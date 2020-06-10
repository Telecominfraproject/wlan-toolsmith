variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "billing_alarm_notify_emails" {
  description = "Billing alarm notification emails"
  type        = set(string)
}

variable "budget_montly_limit" {
  description = "Montly budget limit, USD"
  type        = number
}