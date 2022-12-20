resource "aws_customer_gateway" "tunnel_tip_wifi_fre" {
  bgp_asn    = 65000
  ip_address = data.sops_file.secrets.data["nrg_vpn_endpoint_ip"]
  type       = "ipsec.1"
  tags       = merge({ Name = "tip-wifi-fre-133" }, local.common_tags)
}

resource "aws_customer_gateway" "tunnel_perfecto" {
  bgp_asn    = 65000
  ip_address = data.sops_file.secrets.data["perfecto_ip"]
  type       = "ipsec.1"
  tags       = merge({ Name = "tunnel-perfecto" }, local.common_tags)
}

resource "aws_vpn_connection" "tunnel_tip_wifi_fre" {
  customer_gateway_id = aws_customer_gateway.tunnel_tip_wifi_fre.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tip-wifi-fre" }, local.common_tags)

  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled   = true
      log_group_arn = aws_cloudwatch_log_group.vpn_logs.arn
    }
  }
  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled   = true
      log_group_arn = aws_cloudwatch_log_group.vpn_logs.arn
    }
  }

  lifecycle {
    ignore_changes = [
      tunnel1_ike_versions,
      tunnel1_phase1_dh_group_numbers,
      tunnel1_phase1_encryption_algorithms,
      tunnel1_phase1_integrity_algorithms,
      tunnel1_phase2_dh_group_numbers,
      tunnel1_phase2_encryption_algorithms,
      tunnel1_phase2_integrity_algorithms,
      tunnel1_startup_action,
      tunnel2_ike_versions,
      tunnel2_phase1_dh_group_numbers,
      tunnel2_phase1_encryption_algorithms,
      tunnel2_phase1_integrity_algorithms,
      tunnel2_phase2_dh_group_numbers,
      tunnel2_phase2_encryption_algorithms,
      tunnel2_phase2_integrity_algorithms
    ]
  }
}

resource "aws_vpn_connection" "tunnel-perfecto" {
  customer_gateway_id = aws_customer_gateway.tunnel_perfecto.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tunnel-perfecto" }, local.common_tags)

  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled   = true
      log_group_arn = aws_cloudwatch_log_group.vpn_logs.arn
    }
  }
  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled   = true
      log_group_arn = aws_cloudwatch_log_group.vpn_logs.arn
    }
  }

  lifecycle {
    ignore_changes = [
      tunnel1_ike_versions,
      tunnel1_phase1_dh_group_numbers,
      tunnel1_phase1_encryption_algorithms,
      tunnel1_phase1_integrity_algorithms,
      tunnel1_phase2_dh_group_numbers,
      tunnel1_phase2_encryption_algorithms,
      tunnel1_phase2_integrity_algorithms,
      tunnel1_startup_action,
      tunnel2_ike_versions,
      tunnel2_phase1_dh_group_numbers,
      tunnel2_phase1_encryption_algorithms,
      tunnel2_phase1_integrity_algorithms,
      tunnel2_phase2_dh_group_numbers,
      tunnel2_phase2_encryption_algorithms,
      tunnel2_phase2_integrity_algorithms
    ]
  }
}
