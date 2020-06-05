data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_sfn_state_machine" "main" {
  name       = var.name
  role_arn   = aws_iam_role.sfn_role.arn
  definition = var.step_function_definition
  tags       = var.tags
}

resource "aws_cloudwatch_log_group" "main" {
  name              = var.name
  retention_in_days = var.cw_logs_retention_period
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
    resources = [aws_ecs_task_definition.main.arn]
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
      aws_iam_role.fargate_task_role.arn,
      aws_iam_role.fargate_execution_role.arn
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
}

resource "aws_iam_role" "fargate_execution_role" {
  name               = "${var.name}-execution-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_execution_role_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "fargate_execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "fargate_repo_backup_execution_role" {
  name   = var.name
  role   = aws_iam_role.fargate_execution_role.id
  policy = data.aws_iam_policy_document.fargate_execution_role_policy.json
}

data "aws_iam_policy_document" "fargate_execution_role_policy" {
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
      aws_ecr_repository.main.arn
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
      aws_cloudwatch_log_group.main.arn
    ]
  }
}

resource "aws_iam_role" "fargate_task_role" {
  name               = "${var.name}-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_execution_role_assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "fargate_task_role" {
  name   = var.name
  role   = aws_iam_role.fargate_task_role.id
  policy = var.task_role_policy
}

resource "aws_ecr_repository" "main" {
  name = var.name
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.name
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_execution_role.arn
  task_role_arn            = aws_iam_role.fargate_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${aws_ecr_repository.main.repository_url}:latest",
    "memory": ${var.memory},
    "cpu": ${var.cpu},
     "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
           "awslogs-group" : "${aws_cloudwatch_log_group.main.name}",
           "awslogs-region": "${data.aws_region.current.name}",
           "awslogs-stream-prefix": "ecs"
        }
     },
    "environment": ${jsonencode(var.task_environment)},
    "secrets": ${jsonencode(var.task_secrets)}
  }
]
EOF

  tags = var.tags
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