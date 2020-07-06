aws_region = "us-east-1"

backup_timeout = 3600

fargate_task_public_ip_enabled = true

github_organization = "Telecominfraproject"

s3_bucket_backup_name = "telecominfraproject-backup"

repo_blacklist = [
  "TelecomInfraSWStack",
  "OpenCellular",
]

atlassian_account_id = "telecominfraproject"

sns_backup_notification = [
  {
    protocol = "email",
    endpoint = "eugene@opsfleet.com"
  },
  {
    protocol = "email",
    endpoint = "tipdevops@launchcg.com"
  },
]

cloudwatch_logs_retention_period = 30

backup_retention_period = 60

atlassian_backup_schedule = "cron(30 2 */2 * ? *)"

repo_backup_schedule = "cron(0 9 * * ? *)"