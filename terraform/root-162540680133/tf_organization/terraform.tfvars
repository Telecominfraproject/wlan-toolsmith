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
    "monthly_budget" = "7000.0"
    "billing_alarm_notify_emails" = [
      "dorongivoni@fb.com",
      "jcrosby@launchcg.com",
    ]
  }

  "wifi" = {
    "email"          = "wifi-admin@telecominfraproject.com"
    "monthly_budget" = "5000.0"
    "billing_alarm_notify_emails" = [
      "jaspreetsachdev@fb.com",
      "tip-alerts@opsfleet.com",
      "jcrosby@launchcg.com",
      "dmitry.toptygin@connectus.ai",
      "chrisbusch@fb.com",
    ]
  }

  "openautomation" = {
    "email"          = "netauto-admin@telecominfraproject.com"
    "monthly_budget" = "800.0"
    "billing_alarm_notify_emails" = [
      "dorongivoni@fb.com",
      "jcrosby@launchcg.com",
    ]
  }
}
