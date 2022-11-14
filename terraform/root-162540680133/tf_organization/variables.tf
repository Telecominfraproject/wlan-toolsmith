variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "billing_alarm_notify_emails" {
  description = "Billing alarm notification emails"
  type        = set(string)
}

variable "budget_monthly_limit" {
  description = "Monthly budget limit, USD"
  type        = map(string)
}

variable "org_accounts" {
  description = "Organization accounts"
}
