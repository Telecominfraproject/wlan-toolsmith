variable "name" {
  description = "StepFunction name"
  type        = string
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

variable "cron_schedule" {
  description = "Cron schedule"
  type        = string
}

variable "ecs_task_definition" {
  description = "ECS Task defintion ARN"
  type        = string
}

variable "ecs_task_role" {
  description = "ECS Task role ARN"
  type        = string
}

variable "ecs_task_execution_role" {
  description = "ECS Task execution role ARN"
  type        = string
}

variable "sns_notification_arn" {
  description = "SNS notification ARN"
  type        = string
}