resource "aws_sns_topic" "cost_anomaly_updates" {
  name = "CostAnomalyUpdates"
}

resource "aws_sns_topic_subscription" "cost_anomaly_subscription" {
  for_each  = toset(["tip-alerts@opsfleet.com", "jaspreetsachdev@meta.com"])
  topic_arn = aws_sns_topic.cost_anomaly_updates.arn
  protocol  = "email"
  endpoint  = each.value
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "AWSAnomalyDetectionSNSPublishingPermissions"

    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.cost_anomaly_updates.arn,
    ]
  }

  statement {
    sid = "__default_statement_ID"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account-id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.cost_anomaly_updates.arn,
    ]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.cost_anomaly_updates.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_ce_anomaly_monitor" "wifi_cost_anomaly_monitor" {
  name              = "WiFiCostAnomalyMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "realtime_subscription" {
  name      = "RealtimeAnomalySubscription"
  threshold = 100
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.wifi_cost_anomaly_monitor.arn,
  ]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly_updates.arn
  }

  depends_on = [
    aws_sns_topic_policy.default,
  ]
}
