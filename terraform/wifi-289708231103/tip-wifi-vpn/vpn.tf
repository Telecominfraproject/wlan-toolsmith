// to be deleted
resource "aws_customer_gateway" "tip_wifi_nrg" {
  bgp_asn    = 65000
  ip_address = var.vpn_endpoint_ip
  type       = "ipsec.1"

  tags = {
    Name = "tip-wifi-nrg"
  }
}

// to be deleted
resource "aws_vpn_connection" "tip_wifi_nrg" {
  customer_gateway_id = aws_customer_gateway.tip_wifi_nrg.id
  transit_gateway_id  = module.tgw_main.this_ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "tip-wifi-nrg"
  }
}

resource "aws_customer_gateway" "tunnel_tip_wifi_nrg" {
  bgp_asn    = 65000
  ip_address = var.nrg_vpn_endpoint_ip
  type       = "ipsec.1"

  tags = {
    Name = "tip-wifi-nrg"
  }
}

resource "aws_vpn_connection" "tunnel_tip_wifi_nrg" {
  customer_gateway_id = aws_customer_gateway.tunnel_tip_wifi_nrg.id
  transit_gateway_id  = module.tgw_main.this_ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "tunnel-tip-wifi-nrg"
  }
}
