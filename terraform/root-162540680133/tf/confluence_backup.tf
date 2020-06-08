module "confluence_backup_ecs_task" {
  source = "../modules/aws_ecs_task"
  name   = "confluence-backup"
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

module "confluence_backup" {
  name                     = "confluence-backup"
  source                   = "../modules/aws_stepfunction"
  cron_schedule            = var.atlassian_backup_schedule
  step_function_definition = <<EOF
{
  "Comment": "Runs periodical backup Confluence to s3",
  "StartAt": "StartFargateTask",
  "States": {
    "StartFargateTask": {
      "Type": "Task",
      "Resource":"arn:aws:states:::ecs:runTask.sync",
      "TimeoutSeconds": ${var.backup_timeout},
      "Parameters":{
        "LaunchType":"FARGATE",
        "Cluster": "${aws_ecs_cluster.automation.arn}",
        "TaskDefinition": "${module.confluence_backup_ecs_task.ecs_task_definition}",
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
  ecs_task_definition      = module.confluence_backup_ecs_task.ecs_task_definition
  ecs_task_execution_role  = module.confluence_backup_ecs_task.ecs_execution_role
  ecs_task_role            = module.confluence_backup_ecs_task.ecs_task_role
}