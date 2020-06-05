resource "aws_sfn_state_machine" "repo_backup" {
  name       = "repo-backup"
  role_arn   = aws_iam_role.sfn_repo_backup.arn
  definition = <<EOF
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
        "TaskDefinition": "${aws_ecs_task_definition.repo_backup.arn}",
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

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "repo_backup" {
  name              = "repo-backup"
  retention_in_days = 30
}