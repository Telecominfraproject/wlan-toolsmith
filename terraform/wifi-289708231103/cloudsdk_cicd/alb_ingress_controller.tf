module "alb_ingress_iam_role" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v2.25.0"
  role_name    = "${module.eks.cluster_id}-alb-ingress"
  provider_url = local.oidc_provider_url
  role_policy_arns = [
    aws_iam_policy.alb_ingress_iam_policy.arn,
  ]
  create_role = true
  tags        = local.common_tags
}

data "http" "alb_ingress_policy_json" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_ingress_iam_policy" {
  name_prefix = "alb-ingress-iam-policy-"
  description = "ALB ingress policy for cluster ${local.cluster_name}"
  policy      = data.http.alb_ingress_policy_json.body
}
