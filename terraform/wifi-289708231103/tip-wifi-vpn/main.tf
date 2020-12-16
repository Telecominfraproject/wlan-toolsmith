provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

terraform {
  required_version = "~> 0.13.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-vpn"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "wlan_main" {
  backend = "s3"

  config = {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-main"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}