variable "name" {
  description = "StepFunction name"
  type        = string
}

variable "cw_logs_retention_period" {
  description = "CloudWatch Logs retention period, days"
  type        = number
  default     = 1
}

variable "step_function_definition" {
  description = "StepFunction definition https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "task_role_policy" {
  description = "ECS Task role IAM policy"
  type        = string
}

variable "cpu" {
  description = "ECS Task cpu"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "ECS Task memory"
  type        = number
  default     = 2048
}

variable "task_environment" {
  description = "ECS Task environment"
  type        = map(string)
}

variable "task_secrets" {
  description = "ECS Task secrets"
  type        = map(string)
}

variable "cron_schedule" {
  description = "Cron schedule"
  type        = string
}