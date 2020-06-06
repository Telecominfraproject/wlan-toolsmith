resource "aws_iam_role" "sfn_repo_backup" {
  name               = "sfn-repo-backup"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sfn_repo_backup_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "sfn_repo_backup_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sfn_repo_backup" {
  name   = "sfn-repo-backup"
  role   = aws_iam_role.sfn_repo_backup.id
  policy = data.aws_iam_policy_document.sfn_repo_backup_policy.json
}

data "aws_iam_policy_document" "sfn_repo_backup_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask",
    ]
    resources = [aws_ecs_task_definition.repo_backup.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.fargate_repo_backup_task_role.arn,
      aws_iam_role.fargate_repo_backup_execution_role.arn
    ]
  }

  statement {
    sid    = "SNSPublish"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.repo_backup.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]
    resources = [
      "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
    ]
  }
}

resource "aws_iam_role" "fargate_repo_backup_execution_role" {
  name               = "fargate-repo-backup-execution-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_repo_backup_execution_role_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "fargate_repo_backup_execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "fargate_repo_backup_execution_role" {
  name   = "fargate-repo-backup-execution-role"
  role   = aws_iam_role.fargate_repo_backup_execution_role.id
  policy = data.aws_iam_policy_document.fargate_repo_backup_execution_role_policy.json
}

data "aws_iam_policy_document" "fargate_repo_backup_execution_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      aws_ecr_repository.repo_backup.arn
    ]
  }

  statement {
    sid    = "AWSLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.repo_backup.arn
    ]
  }

  statement {
    sid    = "SSMParater"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      aws_ssm_parameter.github_token.arn
    ]
  }
}

resource "aws_iam_role" "fargate_repo_backup_task_role" {
  name               = "fargate-repo-backup-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_repo_backup_execution_role_assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "fargate_repo_backup_task_role" {
  name   = "fargate-repo-backup-task-role"
  role   = aws_iam_role.fargate_repo_backup_task_role.id
  policy = data.aws_iam_policy_document.fargate_repo_backup_task_role_policy.json
}

data "aws_iam_policy_document" "fargate_repo_backup_task_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = ["*"]
  }
}