data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "main" {
  name              = var.name
  retention_in_days = var.cw_logs_retention_period
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.name}-execution-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecs_execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_execution_role" {
  name   = var.name
  role   = aws_iam_role.ecs_execution_role.id
  policy = data.aws_iam_policy_document.ecs_execution_role_policy.json
}

data "aws_iam_policy_document" "ecs_execution_role_policy" {
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
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_execution_role_additional" {
  name   = "${var.name}-additional-policy"
  role   = aws_iam_role.ecs_execution_role.id
  policy = var.ecs_execution_role_policy
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.name}-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role" {
  name   = var.name
  role   = aws_iam_role.ecs_task_role.id
  policy = var.task_role_policy
}

resource "aws_ecr_repository" "main" {
  name = var.name
}

resource "aws_ecs_task_definition" "sfn" {
  family                   = var.name
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  ephemeral_storage {
    size_in_gib            = var.ephemeral_storage_size
  }
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
