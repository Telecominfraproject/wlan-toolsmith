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

# gh-actions-user
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

# quali-poc
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

# gh-actions-wlan-test-bss
resource "aws_iam_user" "gh-actions-wlan-test-bss" {
  name = "gh-actions-wlan-test-bss"
  path = "/"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "lb_ro_gh_wlan_test_bss" {
  name   = "eks-list-access"
  user   = aws_iam_user.gh-actions-wlan-test-bss.name
  policy = data.aws_iam_policy_document.gh-actions-policy.json
}

# gh-actions-toolsmith
resource "aws_iam_user" "gh-actions-toolsmith" {
  name = "gh-actions-toolsmith"
  path = "/"
  tags = local.common_tags
}

resource "aws_iam_user_policy" "lb_ro_gh_toolsmith" {
  name   = "eks-list-access"
  user   = aws_iam_user.gh-actions-toolsmith.name
  policy = data.aws_iam_policy_document.gh-actions-policy.json
}
