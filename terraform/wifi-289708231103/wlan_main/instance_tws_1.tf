data "aws_ami" "wlan_tws_1" {
  owners      = [var.root_org_account]
  most_recent = true

  filter {
    name   = "name"
    values = ["TWS_EC2-1"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "wlan_tws_1" {
  ami                    = data.aws_ami.wlan_tws_1.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc_main.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.wlan.id]
  key_name               = aws_key_pair.wlan.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    "Name" : "${var.org}-${var.project}-${var.env}-TWS_EC2-1"
  }
}

resource "aws_eip" "wlan_tws_1" {
  vpc      = true
  instance = aws_instance.wlan_tws_1.id
}

output "wlan_tws_1_instance" {
  value = aws_eip.wlan_tws_1.public_ip
}