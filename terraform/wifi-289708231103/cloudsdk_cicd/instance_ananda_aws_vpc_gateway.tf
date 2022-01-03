resource "aws_key_pair" "ananda_gateway_wifi_6195" {
  key_name   = "ananda-gateway-wifi-6195"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpNaE2RZszhukNHGQQCN52zVofJ+iIg9RsD9yoS2zEX"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "ananda_install" {
  template = file("templates/install_ananda.sh.tpl")

  vars = {
    aws_vpc_gateway_token = data.sops_file.aws_vpc_gateway_token.data["aws_vpc_gateway_token"]
  }
}

data "sops_file" "aws_vpc_gateway_token" {
  source_file = "aws_vpc_gateway_token.enc.json"
}

data "sops_file" "ananda_gateway_wifi_6195_key" {
  source_file = "ananda_gateway_wifi_6195_key.enc.json"
}

resource "aws_secretsmanager_secret" "ananda_gateway_wifi_6195_key" {
  name = "ananda-gateway-wifi-6195-key"
}

resource "aws_secretsmanager_secret_version" "ananda_gateway_wifi_6195_key" {
  secret_id     = aws_secretsmanager_secret.ananda_gateway_wifi_6195_key.id
  secret_string = data.sops_file.ananda_gateway_wifi_6195_key.data["ananda_gateway_wifi_6195_key"]
}

resource "aws_security_group" "ananda_aws_vpc_gateway" {
  name   = "Ananda AWS VPC gateway"
  vpc_id = module.vpc_main.vpc_id

  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Public SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow any inbound traffic from VPC network"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ananda_aws_vpc_gateway" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "c4.large"
  subnet_id              = module.vpc_main.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ananda_aws_vpc_gateway.id]
  key_name               = aws_key_pair.ananda_gateway_wifi_6195.id
  user_data              = data.template_file.ananda_install.rendered

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = merge({
    "Name" : "${var.org}-${var.project}-${var.env} Ananda AWS VPC gateway (WIFI-6195)"
  }, local.common_tags)
}

resource "aws_eip" "ananda_aws_vpc_gateway" {
  vpc      = true
  instance = aws_instance.ananda_aws_vpc_gateway.id
  tags     = local.common_tags
}

output "ananda_aws_vpc_gateway_instance" {
  value = aws_eip.ananda_aws_vpc_gateway.public_ip
}
