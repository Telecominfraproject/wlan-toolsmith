resource "aws_customer_gateway" "tunnel_tip_wifi_nrg" {
  bgp_asn    = 65000
  ip_address = var.nrg_vpn_endpoint_ip
  type       = "ipsec.1"
  tags       = merge({ Name = "tip-wifi-fre" }, local.common_tags)
}

resource "aws_vpn_connection" "tunnel_tip_wifi_nrg" {
  customer_gateway_id = aws_customer_gateway.tunnel_tip_wifi_nrg.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tip-wifi-fre" }, local.common_tags)

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
