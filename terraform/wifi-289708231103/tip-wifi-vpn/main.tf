provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-vpn"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
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

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}
