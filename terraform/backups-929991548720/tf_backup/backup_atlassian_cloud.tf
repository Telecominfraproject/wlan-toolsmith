locals {
  sfn_atlassian_subject = "Atlassian Cloud backup failure"
  sfn_atlassian_message = "AWS StepFunction for Atlassian Cloud backup failed, please see Cloudwatch logs for details at https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/backup-atlassian-cloud"
}

module "backup_atlassian_cloud_ecs_task" {
  source = "../modules/aws_ecs_task"
  name   = "backup-atlassian-cloud"
  task_environment = [
    { name : "AWS_REGION", value : var.aws_region },
    { name : "BACKUP_BUCKET", value : aws_s3_bucket.repo_backup.id },
    { name : "ATLASSIAN_ACCOUNT_ID", value : var.atlassian_account_id },
  ]
  task_secrets = [
    { name : "ATLASSIAN_USER", valueFrom : aws_ssm_parameter.atlassian_user.arn },
    { name : "ATLASSIAN_TOKEN", valueFrom : aws_ssm_parameter.atlassian_token.arn },
  ]
  task_role_policy          = data.aws_iam_policy_document.backup_atlassian_cloud_task_role_policy.json
  ecs_execution_role_policy = data.aws_iam_policy_document.backup_atlassian_cloud_execution_role_policy.json
  cw_logs_retention_period  = var.cloudwatch_logs_retention_period
  ephemeral_storage_size    = var.ephemeral_storage_size
}

module "backup_atlassian_cloud" {
  name                     = "backup-atlassian-cloud"
  source                   = "../modules/aws_stepfunction"
  cron_schedule            = var.atlassian_backup_schedule
  step_function_definition = <<EOF
{
  "Comment": "Backup Atlassian Cloud to s3",
  "StartAt": "StartFargateTask",
  "States": {
    "StartFargateTask": {
      "Type": "Task",
      "Resource":"arn:aws:states:::ecs:runTask.sync",
      "TimeoutSeconds": ${var.backup_timeout},
      "Parameters":{
        "LaunchType":"FARGATE",
        "Cluster": "${aws_ecs_cluster.automation.arn}",
        "TaskDefinition": "${module.backup_atlassian_cloud_ecs_task.ecs_task_definition}",
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
        "Subject": "${local.sfn_atlassian_subject}",
        "Message": "${local.sfn_atlassian_message}",
        "TopicArn": "${aws_sns_topic.atlassian_cloud_backup.arn}"
      },
      "Next": "FailState"
    },
    "FailState": {
      "Type": "Fail"
    }
  }
}
EOF
  ecs_task_definition      = module.backup_atlassian_cloud_ecs_task.ecs_task_definition
  ecs_task_execution_role  = module.backup_atlassian_cloud_ecs_task.ecs_execution_role
  ecs_task_role            = module.backup_atlassian_cloud_ecs_task.ecs_task_role
  sns_notification_arn     = aws_sns_topic.atlassian_cloud_backup.arn
}

data "aws_iam_policy_document" "backup_atlassian_cloud_task_role_policy" {
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

data "aws_iam_policy_document" "backup_atlassian_cloud_execution_role_policy" {
  statement {
    sid    = "SSMParater"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      aws_ssm_parameter.atlassian_user.arn,
      aws_ssm_parameter.atlassian_token.arn,
    ]
  }
}

resource "aws_ssm_parameter" "atlassian_user" {
  name  = "/sfn/atlassian-user"
  type  = "SecureString"
  value = "undefined"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "atlassian_token" {
  name  = "/sfn/atlassian-token"
  type  = "SecureString"
  value = "undefined"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_sns_topic" "atlassian_cloud_backup" {
  name = "atlassian-cloud-backup"
}

resource "aws_cloudformation_stack" "atlassian_cloud_backup_email_notification" {
  name          = "atlassian-cloud-backup"
  template_body = <<EOT
AWSTemplateFormatVersion: 2010-09-09
Resources:
%{~for subscription in var.sns_backup_notification}
  Subscription${md5(subscription["endpoint"])}:
    Type: AWS::SNS::Subscription
    Properties:
      Endpoint: "${subscription["endpoint"]}"
      Protocol: "${subscription["protocol"]}"
      TopicArn: "${aws_sns_topic.atlassian_cloud_backup.arn}"
%{endfor~}
EOT

  tags = var.tags
}

output "backup_atlassian_cloud_ecr_url" {
  value = module.backup_atlassian_cloud_ecs_task.ecr_url
}
