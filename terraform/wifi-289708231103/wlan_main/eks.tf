provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-eks?ref=v12.2.0"
  cluster_name = local.cluster_name
  subnets      = module.vpc_main.private_subnets
  vpc_id       = module.vpc_main.vpc_id
  tags         = merge({ "Name" = local.cluster_name }, local.tags)

  workers_group_defaults = {
    ami_type           = "AL2_x86_64"
    disk_size          = var.node_group_settings["disk_size"]
    kubelet_extra_args = "--kube-reserved cpu=500m,memory=2Gi,ephemeral-storage=1Gi --system-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%"
  }

  worker_groups = [
    {
      name             = "main"
      desired_capacity = var.node_group_settings["desired_capacity"]
      max_capacity     = var.node_group_settings["max_capacity"]
      min_capacity     = var.node_group_settings["min_capacity"]
      instance_type    = var.node_group_settings["instance_type"]
      k8s_labels = {
        role = "default"
      }
      additional_tags = local.tags
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
}

locals {
  oidc_provider_url           = split("https://", module.eks.cluster_oidc_issuer_url)[1]
  cluster_main_node_group_asg = length(module.eks.node_groups) > 0 ? module.eks.node_groups["main"]["resources"][0]["autoscaling_groups"][0]["name"] : ""
  public_subnets_merged       = join(" ", module.vpc_main.public_subnets)
  private_subnets_merged      = join(" ", module.vpc_main.private_subnets)
  cluster_name                = "${var.org}-${var.project}-${var.env}"
  tags = {
    "Env"     = var.env
    "Project" = var.project
  }
  admin_roles = [for role in var.eks_admin_roles : {
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
    username = "admin",
    groups   = ["system:masters"]
  }]
}

output "kubeconfig" {
  value = <<EOF

 ========
 ${module.eks.kubeconfig}
 ========
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
  source           = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v2.12.0"
  role_name        = "${module.eks.cluster_id}-external-dns"
  provider_url     = local.oidc_provider_url
  role_policy_arns = [aws_iam_policy.external_dns.arn]
  create_role      = true
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
      "arn:aws:route53:::hostedzone/${data.terraform_remote_state.route_53.outputs.zone_id}"
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

output "external_dns_role_arn" {
  value = module.external_dns_cluster_role.this_iam_role_arn
}

module "cluster_autoscaler_cluster_role" {
  source           = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v2.12.0"
  role_name        = "${module.eks.cluster_id}-cluster-autoscaler"
  provider_url     = local.oidc_provider_url
  role_policy_arns = [aws_iam_policy.cluster_autoscaler.arn]
  create_role      = true
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

output "cluster_autoscaler_role_arn" {
  value = module.cluster_autoscaler_cluster_role.this_iam_role_arn
}
