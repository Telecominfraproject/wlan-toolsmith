provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_subnet" "private_az" {
  for_each = toset(module.vpc_main.private_subnets)
  id       = each.key
}

module "eks" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-eks?ref=v12.2.0"
  cluster_name = local.cluster_name
  subnets      = module.vpc_main.private_subnets
  vpc_id       = module.vpc_main.vpc_id
  tags         = merge({ "Name" = local.cluster_name }, local.common_tags)

  workers_group_defaults = {
    ami_type           = "AL2_x86_64"
    kubelet_extra_args = "--kube-reserved cpu=500m,memory=500Mi,ephemeral-storage=1Gi --system-reserved cpu=250m,memory=500Mi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%"
  }

  worker_ami_name_filter = var.node_group_settings["ami_name"]

  worker_groups = concat([
    for subnet in module.vpc_main.private_subnets :
    {
      name                 = format("default-%s", data.aws_subnet.private_az[subnet].availability_zone)
      asg_desired_capacity = var.node_group_settings["min_capacity"]
      asg_max_size         = var.node_group_settings["max_capacity"]
      asg_min_size         = var.node_group_settings["min_capacity"]
      instance_type        = var.node_group_settings["instance_type"]
      additional_userdata  = local.worker_additional_userdata
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal --allowed-unsafe-sysctls net.ipv4.tcp_keepalive_intvl,net.ipv4.tcp_keepalive_probes,net.ipv4.tcp_keepalive_time"
      subnets              = [subnet]
      tags = [
        {
          key : "k8s.io/cluster-autoscaler/enabled",
          value : true,
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/${local.cluster_name}",
          value : true
          propagate_at_launch : true,
        },
      ]
    }
    ], [
    for subnet in module.vpc_main.private_subnets :
    # testing nodes with taints
    {
      name                 = format("tests-%s", data.aws_subnet.private_az[subnet].availability_zone)
      asg_desired_capacity = var.node_group_settings["min_capacity"]
      asg_max_size         = var.node_group_settings["max_capacity"]
      asg_min_size         = var.node_group_settings["min_capacity"]
      instance_type        = var.testing_instance_type
      additional_userdata  = local.worker_additional_userdata
      kubelet_extra_args   = "--node-labels=node.kubernetes.io/lifecycle=normal,project=ucentral,env=tests --register-with-taints tests=true:NoSchedule --allowed-unsafe-sysctls net.ipv4.tcp_keepalive_intvl,net.ipv4.tcp_keepalive_probes,net.ipv4.tcp_keepalive_time"
      subnets              = [subnet]
      tags = [
        {
          key : "k8s.io/cluster-autoscaler/enabled",
          value : true,
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/${local.cluster_name}",
          value : true
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/node-template/label/project",
          value : "ucentral",
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/node-template/label/env",
          value : "tests",
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/node-template/taint/tests",
          value : "true:NoSchedule",
          propagate_at_launch : true,
        },
      ]
    }
  ])

  worker_groups_launch_template = [
    for subnet in module.vpc_main.private_subnets :
    {
      name                    = format("spot-%s", data.aws_subnet.private_az[subnet].availability_zone)
      override_instance_types = var.spot_instance_types
      spot_max_price          = "" # default to on-demand price
      asg_max_size            = var.node_group_settings["max_capacity"]
      asg_min_size            = 0
      asg_desired_capacity    = 0
      subnets                 = [subnet]
      additional_userdata     = local.worker_additional_userdata
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot --allowed-unsafe-sysctls net.ipv4.tcp_keepalive_intvl,net.ipv4.tcp_keepalive_probes,net.ipv4.tcp_keepalive_time"
      tags = [
        {
          key : "k8s.io/cluster-autoscaler/enabled",
          value : true,
          propagate_at_launch : true,
        },
        {
          key : "k8s.io/cluster-autoscaler/${local.cluster_name}",
          value : true
          propagate_at_launch : true,
        },
      ]
    }
  ]

  workers_additional_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  ]

  enable_irsa = true
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  cluster_version               = var.cluster_version
  write_kubeconfig              = false
  cluster_log_retention_in_days = var.cluster_log_retention_in_days
  map_roles                     = local.admin_roles
  map_users                     = local.eks_access_user_roles
}

locals {
  oidc_provider_url           = split("https://", module.eks.cluster_oidc_issuer_url)[1]
  cluster_main_node_group_asg = length(module.eks.node_groups) > 0 ? module.eks.node_groups["main"]["resources"][0]["autoscaling_groups"][0]["name"] : ""
  public_subnets_merged       = join(" ", module.vpc_main.public_subnets)
  private_subnets_merged      = join(" ", module.vpc_main.private_subnets)
  cluster_name                = "${var.org}-${var.project}-${var.env}"
  common_tags = {
    "Env"       = var.env
    "Project"   = var.project
    "ManagedBy" = "terraform"
  }
  eks_access_user_roles = [for user in var.eks_access_users : { userarn = aws_iam_user.eks_access_users[user].arn, username = aws_iam_user.eks_access_users[user].name, groups = ["system:masters"] }]
  admin_roles = [for role in var.eks_admin_roles : {
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
    username = "admin",
    groups   = ["system:masters"]
  }]
  worker_additional_userdata = <<EOF
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
EOF
}

data "terraform_remote_state" "route_53" {
  backend = "s3"

  config = {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "dns"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

module "external_dns_cluster_role" {
  source           = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v2.25.0"
  role_name        = "${module.eks.cluster_id}-external-dns"
  provider_url     = local.oidc_provider_url
  role_policy_arns = [aws_iam_policy.external_dns.arn]
  create_role      = true
  tags             = local.common_tags
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "external-dns"
  description = "EKS external-dns policy for cluster ${local.cluster_name}"
  policy      = data.aws_iam_policy_document.external_dns.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid = "GrantModifyAccessToDomains"

    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:route53:::hostedzone/${data.terraform_remote_state.route_53.outputs.zone_id}",
    ]
  }

  statement {
    sid = "GrantListAccessToDomains"

    # route53:ListHostedZonesByName is not needed by external-dns, but is needed by cert-manager
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
    ]

    effect = "Allow"

    resources = ["*"]
  }

  # route53:GetChange is not needed by external-dns, but is needed by cert-manager
  statement {
    sid = "GrantGetChangeStatus"

    actions = [
      "route53:GetChange",
    ]

    effect = "Allow"

    resources = ["arn:aws:route53:::change/*"]
  }
}

module "cluster_autoscaler_cluster_role" {
  source           = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v2.25.0"
  role_name        = "${module.eks.cluster_id}-cluster-autoscaler"
  provider_url     = local.oidc_provider_url
  role_policy_arns = [aws_iam_policy.cluster_autoscaler.arn]
  create_role      = true
  tags             = local.common_tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${local.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${local.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}
