resource "aws_cloudwatch_dashboard" "vpn_tg" {
  dashboard_name = "vpn_transit_gateway"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 12,
            "y": 1,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/TransitGateway", "PacketsIn", "TransitGateway", "${module.tgw_main.ec2_transit_gateway_id}" ],
                    [ ".", "PacketsOut", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n# Transit Gateway Perfecto\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 1,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/TransitGateway", "BytesIn", "TransitGateway", "${module.tgw_main.ec2_transit_gateway_id}" ],
                    [ ".", "BytesOut", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 7,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/TransitGateway", "PacketDropCountBlackhole", "TransitGateway", "${module.tgw_main.ec2_transit_gateway_id}" ],
                    [ ".", "PacketDropCountNoRoute", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "title": "Packet Drops",
                "stat": "Sum",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 7,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/TransitGateway", "BytesDropCountNoRoute", "TransitGateway", "${module.tgw_main.ec2_transit_gateway_id}" ],
                    [ ".", "BytesDropCountBlackhole", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "title": "Byte Drops",
                "stat": "Sum",
                "period": 300
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 13,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n# VPN Perfecto\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/VPN", "TunnelDataIn", "VpnId", "${aws_vpn_connection.tunnel-perfecto.id}" ],
                    [ ".", "TunnelDataOut", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Sum",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "IF(m1 > 0.5, 0.5, m1)*2*100", "label": "Uptime", "id": "e1", "region": "us-east-2" } ],
                    [ "AWS/VPN", "TunnelState", "VpnId", "${aws_vpn_connection.tunnel-perfecto.id}", { "id": "m1", "period": 300, "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Average",
                "period": 5,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "Uptime",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "title": "Uptime"
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 20,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "\n# VPN TIP WIFI NRG\n"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 21,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/VPN", "TunnelDataOut", "VpnId", "${aws_vpn_connection.tunnel_tip_wifi_nrg.id}" ],
                    [ ".", "TunnelDataIn", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Sum",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 21,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "IF(m2 > 0.5, 0.5, m2)*2*100", "label": "Uptime", "id": "e1", "region": "us-east-2" } ],
                    [ "AWS/VPN", "TunnelState", "VpnId", "${aws_vpn_connection.tunnel_tip_wifi_nrg.id}", { "id": "m2", "visible": false, "period": 300 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-2",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "Uptime",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "title": "Uptime"
            }
        }
    ]
}
EOF
}
