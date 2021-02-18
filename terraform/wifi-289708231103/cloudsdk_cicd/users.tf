resource "aws_iam_user" "gh-actions-user" {
  name = "gh-actions-user"
  path = "/"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "lb_ro" {
  name   = "eks-list-access"
  user   = aws_iam_user.gh-actions-user.name
  policy = data.aws_iam_policy_document.gh-actions-policy.json
}

data "aws_iam_policy_document" "gh-actions-policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user" "quali-poc" {
  name = "quali-poc"
  path = "/"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "lb_ro_quali" {
  name   = "eks-list-access"
  user   = aws_iam_user.quali-poc.name
  policy = data.aws_iam_policy_document.gh-actions-policy.json
}

data "aws_iam_policy_document" "quali-poc-policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }
}
