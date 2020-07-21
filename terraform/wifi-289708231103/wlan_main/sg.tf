resource "aws_security_group" "wlan" {
  name_prefix = "wlan-tmp-"
  vpc_id      = module.vpc_main.vpc_id
  tags        = { "Name" : "${var.env} instance" }
}

resource "aws_security_group_rule" "wlan_ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.wlan.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  //  cidr_blocks = ["50.251.239.81/32", "199.243.89.130/32", "76.226.71.27/32", "67.68.54.134/32", "35.183.190.118/32"]
}

resource "aws_security_group_rule" "wlan_ingress_http" {
  for_each          = toset(["80", "443"])
  from_port         = each.key
  to_port           = each.key
  protocol          = "TCP"
  security_group_id = aws_security_group.wlan.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wlan_ingress_service" {
  for_each          = toset(["1883", "4043", "4200", "6640", "6643"])
  from_port         = each.key
  to_port           = each.key
  protocol          = "TCP"
  security_group_id = aws_security_group.wlan.id
  type              = "ingress"
  cidr_blocks       = ["50.251.239.81/32", "199.243.89.130/32", "76.226.71.27/32", "35.183.190.118/32"]
}

resource "aws_security_group_rule" "wlan_egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}