module "tgw_main" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  name        = "tip-wifi-fre"
  description = "tip-wifi-fre"
  share_tgw   = false
  vpc_attachments = {
    cicd = {
      vpc_id                                          = data.terraform_remote_state.wlan_main.outputs.vpc_id
      subnet_ids                                      = data.terraform_remote_state.wlan_main.outputs.vpc_private_subnets_ids
      dns_support                                     = true
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
    }
  }

  tags = merge({ Name = "tip-wifi-fre" }, local.common_tags)
}

resource "aws_route" "private" {
  for_each               = toset(data.terraform_remote_state.wlan_main.outputs.vpc_private_route_table_ids)
  destination_cidr_block = "10.28.2.0/23"
  route_table_id         = each.key
  transit_gateway_id     = module.tgw_main.ec2_transit_gateway_id
}

resource "aws_ec2_transit_gateway_route" "vpn" {
  destination_cidr_block         = data.sops_file.secrets.data["vpn_endpoint_cidr"]
  transit_gateway_attachment_id  = aws_vpn_connection.tunnel_tip_wifi_fre.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw_main.ec2_transit_gateway_association_default_route_table_id
}
