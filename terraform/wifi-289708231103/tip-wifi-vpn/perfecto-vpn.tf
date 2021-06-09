resource "aws_customer_gateway" "tunnel_perfecto" {
  bgp_asn    = 65000
  ip_address = "23.21.201.213"
  type       = "ipsec.1"
  tags       = merge({ Name = "tunnel-perfecto" }, local.common_tags)
}

resource "aws_vpn_connection" "tunnel-perfecto" {
  customer_gateway_id = aws_customer_gateway.tunnel_perfecto.id
  transit_gateway_id  = module.tgw_main.this_ec2_transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = merge({ Name = "tunnel-perfecto" }, local.common_tags)
}

# resource "aws_ec2_transit_gateway_route" "tunnel-perfecto" {
#   destination_cidr_block         = "198.160.7.240/32"
#   transit_gateway_attachment_id  = aws_vpn_connection.tunnel-perfecto.transit_gateway_attachment_id
#   transit_gateway_route_table_id = module.tgw_main.this_ec2_transit_gateway_association_default_route_table_id
# }
