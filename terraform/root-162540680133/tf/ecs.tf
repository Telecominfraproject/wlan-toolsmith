resource "aws_ecs_cluster" "automation" {
  name = "automation"
  tags = var.tags
}

resource "aws_ecs_task_definition" "repo_backup" {
  family                   = "repo-backup"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_repo_backup_execution_role.arn
  task_role_arn            = aws_iam_role.fargate_repo_backup_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<EOF
[
  {
    "name": "repo-backup",
    "image": "${aws_ecr_repository.repo_backup.repository_url}:latest",
    "memory": 1024,
    "cpu": 1024,
     "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
           "awslogs-group" : "${aws_cloudwatch_log_group.repo_backup.name}",
           "awslogs-region": "${var.aws_region}",
           "awslogs-stream-prefix": "ecs"
        }
     },
    "environment": [
      {"name": "AWS_REGION", "value": "${var.aws_region}"},
      {"name": "BACKUP_BUCKET", "value": "${aws_s3_bucket.repo_backup.id}"},
      {"name": "GITHUB_ORGANIZATION", "value": "${var.github_organization}"},
      {"name": "REPO_BLACKLIST", "value": "${join("|", var.repo_blacklist)}"}
    ],
    "secrets": [
      {
          "name": "GITHUB_TOKEN",
          "valueFrom": "${aws_ssm_parameter.github_token.arn}"
      }
    ]
  }
]
EOF

  tags = var.tags
}