resource "aws_budgets_budget" "main" {
  name              = "test-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_montly_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-DD_00:00", timestamp())

  lifecycle {
    ignore_changes = [time_period_start]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.billing_alarm_notify_emails
  }
}