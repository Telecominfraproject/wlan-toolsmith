provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-main"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
#}
# DISABLED - It's not safe to run any of this terraform
# EKS cluster was built with ../../../eksctl/wifi-289708231103/tip-wlan-main instead of this

resource "aws_key_pair" "wlan" {
  key_name   = "wlan"
  public_key = var.ssh_key
  tags       = local.common_tags
}

data "aws_caller_identity" "current" {}
