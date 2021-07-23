variable "name" {
  description = "ECS task name"
  type        = string
}

variable "cw_logs_retention_period" {
  description = "CloudWatch Logs retention period, days"
  type        = number
  default     = 1
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

variable "ecs_execution_role_policy" {
  description = "ECS Execution role IAM policy"
  type        = string
  default     = ""
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

variable "ephemeral_storage_size" {
  description = "ECS Task ephemeral storage size in GiB"
  type        = number
  default     = 21
}

variable "task_environment" {
  description = "ECS Task environment"
  type        = set(map(string))
}

variable "task_secrets" {
  description = "ECS Task secrets"
  type        = set(map(string))
}
