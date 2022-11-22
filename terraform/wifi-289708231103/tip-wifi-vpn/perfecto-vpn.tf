resource "aws_customer_gateway" "tunnel_perfecto" {
  bgp_asn    = 65000
  ip_address = data.sops_file.secrets.data["perfecto_ip"]
  type       = "ipsec.1"
  tags       = merge({ Name = "tunnel-perfecto" }, local.common_tags)
}

resource "aws_vpn_connection" "tunnel-perfecto" {
  customer_gateway_id = aws_customer_gateway.tunnel_perfecto.id
  transit_gateway_id  = module.tgw_main.ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tunnel-perfecto" }, local.common_tags)
}
