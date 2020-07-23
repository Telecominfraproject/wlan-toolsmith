data "aws_ami" "wlan_candelatech_test_results" {
  owners      = [var.root_org_account]
  most_recent = true

  filter {
    name   = "name"
    values = ["CandelaTech Test Results"]
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

resource "aws_instance" "wlan_candelatech_test_results" {
  ami                    = data.aws_ami.wlan_candelatech_test_results.id
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
    "Name" : "${var.org}-${var.project}-${var.env} CandelaTech Test Results"
  }
}

resource "aws_eip" "wlan_candelatech_test_results" {
  vpc      = true
  instance = aws_instance.wlan_candelatech_test_results.id
}

output "wlan_candelatech_test_results_instance" {
  value = aws_eip.wlan_candelatech_test_results.public_ip
}