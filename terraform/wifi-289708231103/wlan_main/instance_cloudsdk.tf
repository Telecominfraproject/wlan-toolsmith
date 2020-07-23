// cloudsdk master node

resource "aws_instance" "cloudsdk_master" {
  ami                    = "ami-0dae03f46a37a171c"
  instance_type          = "c5.xlarge"
  subnet_id              = module.vpc_main.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.wlan_cloudsdk_master.id]
  key_name               = aws_key_pair.wlan.id

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    "Name" : "${var.org}-${var.project}-${var.env}-cloudsdk-master"
  }
}

//resource "aws_eip" "cloudsdk_master" {
//  vpc      = true
//  instance = aws_instance.cloudsdk_master.id
//}

locals {
  cloudsdk_node_ami = ["ami-0c74f826d8e172088", "ami-0461d920b4a8131d0"]
}

// cloudsdk nodes

resource "aws_instance" "cloudsdk_node" {
  for_each               = toset(local.cloudsdk_node_ami)
  ami                    = each.key
  instance_type          = "t3.xlarge"
  subnet_id              = module.vpc_main.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.wlan_cloudsdk_node.id]
  key_name               = aws_key_pair.wlan.id

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    "Name" : "${var.org}-${var.project}-${var.env}-cloudsdk-node-${index(local.cloudsdk_node_ami, each.key)}"
  }
}

//resource "aws_eip" "cloudsdk_node" {
//  for_each = toset(local.cloudsdk_node_ami)
//  vpc      = true
//  instance = aws_instance.cloudsdk_node[each.key].id
//}

output "wlan_cloudsdk_master_ip" {
  value = aws_instance.cloudsdk_master.public_ip
}

output "wlan_cloudsdk_node_ip" {
  value = [
    for instance in aws_instance.cloudsdk_node :
    instance.public_ip
  ]
}

// cloudsdk master SG

resource "aws_security_group" "wlan_cloudsdk_master" {
  name_prefix = "wlan-cloudsdk-master-"
  vpc_id      = module.vpc_main.vpc_id
  tags        = { "Name" : "${var.env} cloudsdk master" }
}

resource "aws_security_group_rule" "wlan_cloudsdk_master_egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_master.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_master_ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.wlan_cloudsdk_master.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_master_ingress_all_ext" {
  from_port         = 0
  to_port           = 65535
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_master.id
  type              = "ingress"
  cidr_blocks       = ["199.243.89.130/32", "70.50.132.8/32"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_master_ingress_all_self" {
  from_port         = 0
  to_port           = 65535
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_master.id
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "wlan_cloudsdk_master_ingress_all_cloudsdk_node" {
  from_port                = 0
  to_port                  = 65535
  protocol                 = "ALL"
  security_group_id        = aws_security_group.wlan_cloudsdk_master.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.wlan_cloudsdk_node.id
}

// cloudsdk node SG

resource "aws_security_group" "wlan_cloudsdk_node" {
  name_prefix = "wlan-cloudsdk-node-"
  vpc_id      = module.vpc_main.vpc_id
  tags        = { "Name" : "${var.env} cloudsdk node" }
}

resource "aws_security_group_rule" "wlan_cloudsdk_node_egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_node.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_node_ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.wlan_cloudsdk_node.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_node_ingress_all_ext" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_node.id
  type              = "ingress"
  cidr_blocks       = ["199.243.89.130/32"]
}

resource "aws_security_group_rule" "wlan_cloudsdk_node_ingress_all_self" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.wlan_cloudsdk_node.id
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "wlan_cloudsdk_node_ingress_all_cloudsdk_master" {
  from_port                = 0
  to_port                  = 0
  protocol                 = "ALL"
  security_group_id        = aws_security_group.wlan_cloudsdk_node.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.wlan_cloudsdk_master.id
}