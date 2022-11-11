aws_region = "us-east-1"

billing_alarm_notify_emails = [
  "tip-alerts@opsfleet.com"
]

budget_monthly_limit = {
  "cicd" = "100.0"
  "wifi" = "100.0"
}

org_accounts = {
  "cicd" = {
    "email"          = "cicd-admin@telecominfraproject.com"
    "monthly_budget" = "500.0"
    "billing_alarm_notify_emails" = [
      "dorongivoni@fb.com",
      "jcrosby@launchcg.com",
    ]
  }

  "wifi" = {
    "email"          = "wifi-admin@telecominfraproject.com"
    "monthly_budget" = "5000.0"
    "billing_alarm_notify_emails" = [
      "jaspreetsachdev@meta.com",
      "tip-alerts@opsfleet.com",
      "chrisbusch@meta.com",
    ]
  }

  "openautomation" = {
    "email"          = "netauto-admin@telecominfraproject.com"
    "monthly_budget" = "500.0"
    "billing_alarm_notify_emails" = [
      "dorongivoni@fb.com",
      "jcrosby@launchcg.com",
    ]
  }
}
