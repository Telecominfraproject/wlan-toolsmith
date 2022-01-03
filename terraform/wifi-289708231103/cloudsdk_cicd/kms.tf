data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["arn:aws:s3:::*"]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Allow access for Key Administrators"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_5b24211378e8344f",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_SystemAdministrator_622371b0ceece6f8",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/atlantis-ecs_task_execution",
      ]
    }
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type = "AWS"
      identifiers = concat([
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_5b24211378e8344f",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_SystemAdministrator_622371b0ceece6f8",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/atlantis-ecs_task_execution",
        ],
        [for user in var.eks_access_users_with_kms_access : aws_iam_user.eks_access_users[user].arn]
      )
    }
  }

  statement {
    sid = "Allow attachment of persistent resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_5b24211378e8344f",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_SystemAdministrator_622371b0ceece6f8",
      ]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }


  depends_on = [aws_iam_user.eks_access_users]
}

resource "aws_kms_key" "helm_secrets" {
  description = "Helm secrets key"
  policy      = data.aws_iam_policy_document.kms.json
  tags        = local.common_tags
}

resource "aws_kms_alias" "helm_secrets" {
  name          = "alias/helm-secrets"
  target_key_id = aws_kms_key.helm_secrets.key_id
}

resource "aws_kms_key" "terraform_secrets" {
  description = "Terraform secrets key"
  policy      = data.aws_iam_policy_document.kms.json
  tags        = local.common_tags
}

resource "aws_kms_alias" "terraform_secrets" {
  name          = "alias/terraform-secrets"
  target_key_id = aws_kms_key.terraform_secrets.key_id
}
