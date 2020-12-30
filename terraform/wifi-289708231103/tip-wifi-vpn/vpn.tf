resource "aws_customer_gateway" "tunnel_tip_wifi_nrg" {
  bgp_asn    = 65000
  ip_address = var.nrg_vpn_endpoint_ip
  type       = "ipsec.1"
  tags       = merge({ Name = "tip-wifi-nrg" }, local.common_tags)
}

resource "aws_vpn_connection" "tunnel_tip_wifi_nrg" {
  customer_gateway_id = aws_customer_gateway.tunnel_tip_wifi_nrg.id
  transit_gateway_id  = module.tgw_main.this_ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tip-wifi-nrg" }, local.common_tags)
}
