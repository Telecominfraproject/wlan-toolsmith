data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_iam_role.sfn_role]
  create_duration = "30s"
}

resource "aws_sfn_state_machine" "main" {
  name       = var.name
  role_arn   = aws_iam_role.sfn_role.arn
  definition = var.step_function_definition
  tags       = var.tags
  depends_on = [time_sleep.wait_30_seconds]
}

resource "aws_iam_role" "sfn_role" {
  name               = "${var.name}-sfn"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sfn_role_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "sfn_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sfn_role" {
  name   = var.name
  role   = aws_iam_role.sfn_role.id
  policy = data.aws_iam_policy_document.sfn_repo_backup_policy.json
}

data "aws_iam_policy_document" "sfn_repo_backup_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask",
    ]
    resources = [var.ecs_task_definition]
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
      var.ecs_task_role,
      var.ecs_task_execution_role
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
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      var.sns_notification_arn,
    ]
  }
}

resource "aws_cloudwatch_event_rule" "main" {
  name                = var.name
  schedule_expression = var.cron_schedule
}

resource "aws_cloudwatch_event_target" "repo_backup" {
  rule     = aws_cloudwatch_event_rule.main.id
  arn      = aws_sfn_state_machine.main.id
  role_arn = aws_iam_role.cw_trigger.arn
}

resource "aws_iam_role" "cw_trigger" {
  name               = "${var.name}-cw-trigger"
  assume_role_policy = data.aws_iam_policy_document.cw_trigger_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "cw_trigger_assume_policy" {
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

resource "aws_iam_role_policy" "cw_trigger_policy" {
  name   = var.name
  role   = aws_iam_role.cw_trigger.id
  policy = data.aws_iam_policy_document.cw_trigger_policy.json
}

data "aws_iam_policy_document" "cw_trigger_policy" {
  statement {
    sid    = "RunStepFunction"
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      aws_sfn_state_machine.main.id
    ]
  }
}