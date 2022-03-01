provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "openwifi-virtual-ap"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

resource "aws_key_pair" "openwifi_virtual_ap" {
  key_name   = "openwifi-virtual-ap"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzqrsHgptzjmj5CcmM0sBkhmxooEYpcvtxlPYAkDatn"
  tags       = local.common_tags
}

data "aws_ami" "tip_firmware" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "openwifi_virtual_ap" {
  ami                         = data.aws_ami.tip_firmware.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.openwifi_virtual_ap.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = merge({
    "Name" : "${var.org}-${var.project}-${var.env} Openwifi virtual AP (WIFI-7204)"
  }, local.common_tags)
}

resource "aws_s3_bucket" "openwifi_virtual_ap_images" {
  bucket = "openwifi-virtual-ap-images"
  acl    = "private"
  tags   = local.common_tags

  lifecycle_rule {
    id      = "default_retention"
    enabled = true

    expiration {
      days = 60
    }
  }
}

resource "aws_iam_role" "vmimport" {
  name = "vmimport"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "vmie.amazonaws.com" },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:Externalid" : "vmimport"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::openwifi-virtual-ap-images",
          "arn:aws:s3:::openwifi-virtual-ap-images/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketAcl"
        ],
        "Resource" : [
          "arn:aws:s3:::openwifi-virtual-ap-images",
          "arn:aws:s3:::openwifi-virtual-ap-images/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*"
        ],
        "Resource" : "*"
      }
    ]
  })
}