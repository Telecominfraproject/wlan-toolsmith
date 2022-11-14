resource "aws_budgets_budget" "default" {
  for_each          = var.org_accounts
  name              = "${each.key}-budget"
  budget_type       = "COST"
  limit_amount      = each.value["monthly_budget"]
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-DD_00:00", timestamp())

  lifecycle {
    ignore_changes = [time_period_start]
  }

  cost_filters = {
    "LinkedAccount" : aws_organizations_account.default[each.key].id
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = each.value["billing_alarm_notify_emails"]
  }
}
