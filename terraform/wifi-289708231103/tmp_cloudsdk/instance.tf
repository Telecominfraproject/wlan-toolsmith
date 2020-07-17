resource "aws_key_pair" "cloudsdk" {
  key_name   = "cloudsdk_tmp"
  public_key = file("id_rsa.pub")
}

resource "aws_security_group" "cloudsdk" {
  name_prefix = "cloudsdk-"
  vpc_id      = module.vpc.vpc_id
  tags        = { "Name" : "${var.env} instance" }
}

resource "aws_security_group_rule" "ingress_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.cloudsdk.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_all" {
  from_port         = 0
  to_port           = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.cloudsdk.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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

resource "aws_instance" "cloudsdk" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.cloudsdk.id]
  key_name               = aws_key_pair.cloudsdk.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = { "Name" : var.env }
}

resource "aws_eip" "cloudsdk" {
  vpc      = true
  instance = aws_instance.cloudsdk.id
}

output "cloudsdk_instance" {
  value = aws_eip.cloudsdk.public_ip
}