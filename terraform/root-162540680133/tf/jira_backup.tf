module "jira_backup_ecs_task" {
  source = "../modules/aws_ecs_task"
  name   = "jira-backup"
  task_environment = [
    { name : "AWS_REGION", value : var.aws_region },
    { name : "BACKUP_BUCKET", value : aws_s3_bucket.repo_backup.id },
    { name : "ATLASSIAN_ACCOUNT_ID", value : var.atlassian_account_id },
  ]
  task_secrets = [
    { name : "ATLASSIAN_USER", valueFrom : aws_ssm_parameter.atlassian_user.arn },
    { name : "ATLASSIAN_TOKEN", valueFrom : aws_ssm_parameter.atlassian_token.arn },
  ]
  task_role_policy          = data.aws_iam_policy_document.jira_backup_task_role_policy.json
  ecs_execution_role_policy = data.aws_iam_policy_document.jira_backup_execution_role_policy.json
}

module "jira_backup" {
  name                     = "jira-backup"
  source                   = "../modules/aws_stepfunction"
  cron_schedule            = var.atlassian_backup_schedule
  step_function_definition = <<EOF
{
  "Comment": "Runs periodical backups from jira to s3",
  "StartAt": "StartFargateTask",
  "States": {
    "StartFargateTask": {
      "Type": "Task",
      "Resource":"arn:aws:states:::ecs:runTask.sync",
      "TimeoutSeconds": ${var.backup_timeout},
      "Parameters":{
        "LaunchType":"FARGATE",
        "Cluster": "${aws_ecs_cluster.automation.arn}",
        "TaskDefinition": "${module.jira_backup_ecs_task.ecs_task_definition}",
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
  ecs_task_definition      = module.jira_backup_ecs_task.ecs_task_definition
  ecs_task_execution_role  = module.jira_backup_ecs_task.ecs_execution_role
  ecs_task_role            = module.jira_backup_ecs_task.ecs_task_role
}

data "aws_iam_policy_document" "jira_backup_task_role_policy" {
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

data "aws_iam_policy_document" "jira_backup_execution_role_policy" {
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

resource "aws_cloudwatch_event_rule" "jira_backup" {
  name                = "jira-backup"
  schedule_expression = var.atlassian_backup_schedule
}

resource "aws_cloudwatch_event_target" "jira_backup" {
  rule     = aws_cloudwatch_event_rule.jira_backup.id
  arn      = module.jira_backup.sfn_state_machine_id
  role_arn = aws_iam_role.cloudwatch_atlassian_cloud_backup.arn
}

resource "aws_iam_role" "cloudwatch_atlassian_cloud_backup" {
  name               = "cloudwatch-atlassian-cloud-backup"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_atlassian_cloud_backup_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "cloudwatch_atlassian_cloud_backup_assume_policy" {
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

resource "aws_iam_role_policy" "cloudwatch_atlassian_cloud_backup_policy" {
  name   = "cloudwatch-atlassian-cloud-backup"
  role   = aws_iam_role.cloudwatch_atlassian_cloud_backup.id
  policy = data.aws_iam_policy_document.cloudwatch_atlassian_cloud_backup_policy.json
}

data "aws_iam_policy_document" "cloudwatch_atlassian_cloud_backup_policy" {
  statement {
    sid    = "RunStepFunction"
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      module.jira_backup.sfn_state_machine_id
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