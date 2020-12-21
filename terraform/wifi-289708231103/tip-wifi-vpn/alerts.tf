resource "aws_cloudwatch_metric_alarm" "vpn_state" {
  for_each            = { for vpn in [aws_vpn_connection.tunnel_tip_wifi_nrg, aws_vpn_connection.tunnel-perfecto] : vpn.id => vpn }
  alarm_name          = "vpn-state-${each.key}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/VPN"
  dimensions = {
    "VpnId" = each.key
  }
  metric_name       = "TunnelState"
  period            = "60"
  statistic         = "Maximum"
  threshold         = "0"
  alarm_description = "VPN Tunnel State"
  alarm_actions     = [aws_sns_topic.vpn_cloudwatch_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "vpn_outgoing_data" {
  for_each            = { for vpn in [aws_vpn_connection.tunnel_tip_wifi_nrg, aws_vpn_connection.tunnel-perfecto] : vpn.id => vpn }
  alarm_name          = "vpn-outgoing-data-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/VPN"
  dimensions = {
    "VpnId" = each.key
  }
  metric_name       = "TunnelDataOut"
  period            = "3600"
  statistic         = "Sum"
  threshold         = "100000000000" # 100GB
  unit              = "Bytes"
  alarm_description = "VPN Outgoing Data"
  alarm_actions     = [aws_sns_topic.vpn_cloudwatch_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "tgw_incoming" {
  alarm_name          = "tgw-incoming-data-${module.tgw_main.this_ec2_transit_gateway_id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/TransitGateway"
  dimensions = {
    "TransitGateway" = module.tgw_main.this_ec2_transit_gateway_id
  }
  metric_name       = "BytesIn"
  period            = "3600"
  statistic         = "Sum"
  threshold         = "100000000000" # 100GB
  alarm_description = "Transit Gateway Incoming Data"
  alarm_actions     = [aws_sns_topic.vpn_cloudwatch_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "tgw_outgoing_data" {
  alarm_name          = "tgw-outgoing-data-${module.tgw_main.this_ec2_transit_gateway_id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/TransitGateway"
  dimensions = {
    "TransitGateway" = module.tgw_main.this_ec2_transit_gateway_id
  }
  metric_name       = "BytesOut"
  period            = "3600"
  statistic         = "Sum"
  threshold         = "100000000000" # 100GB
  alarm_description = "Transit Gateway Outgoing Data"
  alarm_actions     = [aws_sns_topic.vpn_cloudwatch_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "tgw_packet_drops" {
  alarm_name          = "tgw-packet-drops-${module.tgw_main.this_ec2_transit_gateway_id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Transit Gateway Packet Drops"
  alarm_actions       = [aws_sns_topic.vpn_cloudwatch_alarms.arn]

  metric_query {
    id          = "total_drops"
    expression  = "pd_blackhole + pd_no_route"
    label       = "Total packet drops"
    return_data = "true"
  }

  metric_query {
    id = "pd_blackhole"
    metric {
      namespace = "AWS/TransitGateway"
      dimensions = {
        "TransitGateway" = module.tgw_main.this_ec2_transit_gateway_id
      }
      metric_name = "PacketDropCountBlackhole"
      period      = "300"
      stat        = "Sum"
    }
  }

  metric_query {
    id = "pd_no_route"
    metric {
      namespace = "AWS/TransitGateway"
      dimensions = {
        "TransitGateway" = module.tgw_main.this_ec2_transit_gateway_id
      }
      metric_name = "PacketDropCountNoRoute"
      period      = "300"
      stat        = "Sum"
    }
  }
}

resource "aws_sns_topic" "vpn_cloudwatch_alarms" {
  name = "vpn_cloudwatch_alarms"
}

resource "aws_cloudformation_stack" "atlassian_cloud_backup_email_notification" {
  name          = "atlassian-cloud-backup"
  template_body = <<EOT
AWSTemplateFormatVersion: 2010-09-09
Resources:
%{~for subscription in var.sns_alarm_subscriptions}
  Subscription${md5(subscription["endpoint"])}:
    Type: AWS::SNS::Subscription
    Properties:
      Endpoint: "${subscription["endpoint"]}"
      Protocol: "${subscription["protocol"]}"
      TopicArn: "${aws_sns_topic.vpn_cloudwatch_alarms.arn}"
%{endfor~}
EOT
}

