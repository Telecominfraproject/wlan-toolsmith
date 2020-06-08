variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "az" {
  description = "Availability zones"
  default     = ["a", "b", "c"]
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "backup_timeout" {
  description = "Repository backup job timeout"
  type        = number
}

variable "fargate_task_public_ip_enabled" {
  description = "Fargate task will attempt to receive public ip, set to true if subnet is public"
  type        = bool
}

variable "github_organization" {
  description = "Github organization to backup"
  type        = string
}

variable "repo_backup_schedule" {
  description = "Repo backup cron schedule"
  type        = string
  default     = "cron(0 9 * * ? *)"
}

variable "atlassian_backup_schedule" {
  description = "Atlasssian cloud backup cron schedule"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "s3_bucket_backup_name" {
  description = "Name of s3 bucket to create"
  type        = string
}

variable "s3_bucket_versioning" {
  description = "Enables/disables s3 bucket versioning"
  type        = bool
  default     = false
}

variable "repo_blacklist" {
  description = "Comma separated list of repositories to exclude from backup"
  type        = set(string)
  default     = []
}

variable "atlassian_account_id" {
  description = "Atlassian cloud account id"
  type        = string
}