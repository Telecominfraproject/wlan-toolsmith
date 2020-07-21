provider "aws" {
  version = ">= 2.59.0"
  region  = var.aws_region
}

terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "wlan-main"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}