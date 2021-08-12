data "aws_iam_policy_document" "gh_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user" "eks_access_users" {
  for_each = toset(var.eks_access_users)

  name = each.key
  path = "/"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "eks_access_user_policies" {
  for_each = toset(var.eks_access_users)

  name   = "eks-list-access"
  user   = each.key
  policy = data.aws_iam_policy_document.gh_actions_policy.json

  depends_on = [aws_iam_user.eks_access_users]
}
