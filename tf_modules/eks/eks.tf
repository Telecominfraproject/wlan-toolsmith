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
  cluster_name = var.cluster_name
  subnets      = length(var.vpc_id) > 0 ? module.vpc_main.private_subnets : var.private_subnets
  vpc_id       = length(var.vpc_id) > 0 ? module.vpc_main.vpc_id : var.vpc_id
  tags         = { "Name" = var.cluster_name }

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = var.node_group_settings["disk_size"]
  }

  node_groups = {
    main = {
      desired_capacity = var.node_group_settings["desired_capacity"]
      max_capacity     = var.node_group_settings["max_capacity"]
      min_capacity     = var.node_group_settings["min_capacity"]
      instance_type    = var.node_group_settings["instance_type"]
      k8s_labels = {
        role = "default"
      }
    }
  }

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
}

locals {
  oidc_provider_url           = split("https://", module.eks.cluster_oidc_issuer_url)[1]
  cluster_main_node_group_asg = length(module.eks.node_groups) > 0 ? module.eks.node_groups["main"]["resources"][0]["autoscaling_groups"][0]["name"] : ""
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
  description = "EKS cluster-autoscaler policy for cluster ${var.cluster_name}"
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
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
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

output "kubeconfig" {
  value = module.eks.kubeconfig
}
