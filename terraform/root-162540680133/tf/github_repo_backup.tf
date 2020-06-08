module "github_repo_backup_ecs_task" {
  source = "../modules/aws_ecs_task"
  name   = "github-repo-backup"
  task_environment = [
    { name : "AWS_REGION", value : var.aws_region },
    { name : "BACKUP_BUCKET", value : aws_s3_bucket.repo_backup.id },
    { name : "GITHUB_ORGANIZATION", value : var.github_organization },
    { name : "REPO_BLACKLIST", value : "${join("|", var.repo_blacklist)}" }
  ]
  task_secrets = [
    { name : "GITHUB_TOKEN", valueFrom : aws_ssm_parameter.github_token.arn },
  ]
  task_role_policy          = data.aws_iam_policy_document.github_repo_backup_task_role_policy.json
  ecs_execution_role_policy = data.aws_iam_policy_document.github_repo_backup_execution_role_policy.json
}

module "github_repo_backup" {
  name                     = "github-repo-backup"
  source                   = "../modules/aws_stepfunction"
  cron_schedule            = var.repo_backup_schedule
  step_function_definition = <<EOF
{
  "Comment": "Runs periodical backups from github repositories to s3",
  "StartAt": "StartFargateTask",
  "States": {
    "StartFargateTask": {
      "Type": "Task",
      "Resource":"arn:aws:states:::ecs:runTask.sync",
      "TimeoutSeconds": ${var.backup_timeout},
      "Parameters":{
        "LaunchType":"FARGATE",
        "Cluster": "${aws_ecs_cluster.automation.arn}",
        "TaskDefinition": "${module.github_repo_backup_ecs_task.ecs_task_definition}",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": [
              "${tolist(data.aws_subnet_ids.default.ids)[0]}"
            ],
            "SecurityGroups": ["${aws_security_group.fargate_repo_backup.id}"],
            "AssignPublicIp": "${var.fargate_task_public_ip_enabled ? "ENABLED" : "DISABLED"}"
          }
        }
      },
      "Catch": [
        {
          "ErrorEquals": [ "States.ALL" ],
          "ResultPath": "$.error",
          "Next": "Notify Failure"
        }
      ],
      "End": true
    },
    "Notify Failure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": {
          "ExecutionId.$": "$$.Execution.Id",
          "Error.$": "$.error"
        },
        "TopicArn": "${aws_sns_topic.repo_backup.arn}"
      },
      "Next": "FailState"
    },
    "FailState": {
      "Type": "Fail"
    }
  }
}
EOF
  ecs_task_definition      = module.github_repo_backup_ecs_task.ecs_task_definition
  ecs_task_execution_role  = module.github_repo_backup_ecs_task.ecs_execution_role
  ecs_task_role            = module.github_repo_backup_ecs_task.ecs_task_role
}

data "aws_iam_policy_document" "github_repo_backup_task_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBuckets",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.repo_backup.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.repo_backup.arn}/*"]
  }
}

data "aws_iam_policy_document" "github_repo_backup_execution_role_policy" {
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

resource "aws_ssm_parameter" "github_token" {
  name  = "/sfn/github-token"
  type  = "SecureString"
  value = "undefined"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_sns_topic" "repo_backup" {
  name = "repo_backup"
}

output "github_repo_backup_ecr_url" {
  value = module.github_repo_backup_ecs_task.ecr_url
}