resource "aws_cloudwatch_event_rule" "repo_backup" {
  name                = "repo-backup"
  schedule_expression = var.cron_repo_backup
}

resource "aws_cloudwatch_event_target" "repo_backup" {
  rule     = aws_cloudwatch_event_rule.repo_backup.id
  arn      = aws_sfn_state_machine.repo_backup.id
  role_arn = aws_iam_role.cloudwatch_repo_backup.arn
}

resource "aws_iam_role" "cloudwatch_repo_backup" {
  name               = "cloudwatch-repo-backup"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_repo_backup_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "cloudwatch_repo_backup_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_repo_backup_policy" {
  name   = "cloudwatch-repo-backup"
  role   = aws_iam_role.cloudwatch_repo_backup.id
  policy = data.aws_iam_policy_document.cloudwatch_repo_backup_policy.json
}

data "aws_iam_policy_document" "cloudwatch_repo_backup_policy" {
  statement {
    sid    = "RunStepFunction"
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      aws_sfn_state_machine.repo_backup.id
    ]
  }
}