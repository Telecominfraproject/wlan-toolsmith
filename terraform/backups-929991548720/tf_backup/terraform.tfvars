aws_region = "us-east-1"

backup_timeout = 3600

fargate_task_public_ip_enabled = true

github_organization = "Telecominfraproject"

s3_bucket_backup_name = "telecominfraproject-backups"

repo_blacklist = [
  "TelecomInfraSWStack",
  "OpenCellular",
]

atlassian_account_id = "telecominfraproject"

sns_backup_notification = [
  {
    protocol = "email",
    endpoint = "max@opsfleet.com"
  },
  {
    protocol = "email",
    endpoint = "leonid@opsfleet.com"
  },
  {
    protocol = "email",
    endpoint = "tipdevops@launchcg.com"
  },
]

cloudwatch_logs_retention_period = 30

backup_retention_period = 60

atlassian_backup_schedule = "cron(30 2 ? * WED,SAT *)"

repo_backup_schedule = "cron(0 9 * * ? *)"

