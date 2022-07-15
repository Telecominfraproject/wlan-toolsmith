# This instance is required for FreeRADIUS testing and was created for WIFI-3714 task
resource "aws_key_pair" "dunaev_wifi_3714" {
  key_name   = "dunaev-wifi-3714"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5Sx/9VEFaihrZWtRGc650vJ8vRy1BLDdFwHEYOs2Hnp7b8dY/WYdPjfnHwte9Vo0LZrn0j4ikzbF/WN5b/lpqgPbRcG/sjOHZLND54o6KvDdyKCMMN6kc9ZWvSZ3WM5SUcjMH/ZFbwdbdXx1Kn8h1s4dnkKC6Dc81FPUjtXVRurPraQf3hE7Iy4c/JGBmq/6+71gw9uZZ5qSIakIhOB52C/apV3TyqW/ScIoZAMNgCpbuZwlbE8isd9MtXWv5SuQ3VYNeZbleBK1z7pdWPslVGhms5kLBOFRTr2cTiFP4UDE5MVC3m3f3afBaDOAoDE191nkjiOBndoV+c1p5qHI5"
  tags       = local.common_tags
}

resource "aws_instance" "wlan_freeradius" {
  ami                    = "ami-00399ec92321828f5" # Ubuntu 20.04 amd64
  instance_type          = "t2.micro"
  subnet_id              = module.vpc_main.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.wlan.id]
  key_name               = aws_key_pair.dunaev_wifi_3714.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = merge({
    "Name" : "${var.org}-${var.project}-${var.env} FreeRADIUS server (WIFI-3714)"
  }, local.common_tags)
}

resource "aws_eip" "wlan_freeradius" {
  vpc      = true
  instance = aws_instance.wlan_freeradius.id
  tags     = local.common_tags
}

output "wlan_freeradius_instance" {
  value = aws_eip.wlan_freeradius.public_ip
}

# This instance will also have freeradius installed, but it will be given to the QA team for the internal tests and manual configuration changes that may be backported to the ansible configuration
resource "aws_instance" "wlan_freeradius_qa" {
  ami                    = "ami-00399ec92321828f5" # Ubuntu 20.04 amd64
  instance_type          = "t2.micro"
  subnet_id              = module.vpc_main.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.wlan.id]
  key_name               = aws_key_pair.dunaev_wifi_3714.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = merge({
    "Name" : "${var.org}-${var.project}-${var.env} FreeRADIUS server for QA team (WIFI-5640)"
  }, local.common_tags)
}

resource "aws_eip" "wlan_freeradius_qa" {
  vpc      = true
  instance = aws_instance.wlan_freeradius_qa.id
  tags     = local.common_tags
}

output "wlan_freeradius_qa_instance" {
  value = aws_eip.wlan_freeradius_qa.public_ip
}

resource "null_resource" "ansible_inventory_generate" {
  triggers = {
    freeradius_instance_arn    = aws_instance.wlan_freeradius.arn
    freeradius_eip_id          = aws_eip.wlan_freeradius.id
    freeradius_qa_instance_arn = aws_instance.wlan_freeradius_qa.arn
    freeradius_qa_eip_id       = aws_eip.wlan_freeradius_qa.id
    demo_instance_arn          = aws_instance.wlan_demo.arn
    demo_eip_id                = aws_eip.wlan_demo.id
  }

  # Generate Ansible inventory file
  provisioner "local-exec" {
    command = <<-EOA
    echo "${templatefile("${path.module}/templates/ansible_inventory.yml.tpl", { freeradius_eip = aws_eip.wlan_freeradius, freeradius_eip_qa = aws_eip.wlan_freeradius_qa, demo_eip = aws_eip.wlan_demo })}" > ansible/hosts.yml
    EOA
  }
}

