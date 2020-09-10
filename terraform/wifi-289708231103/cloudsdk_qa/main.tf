provider "aws" {
  version = ">= 2.59.0"
  region  = var.aws_region
}

terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-qa"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "aws_caller_identity" "current" {}