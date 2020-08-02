provider "aws" {
  version = ">= 2.59.0"
  region  = var.aws_region
}

terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "dns"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

resource "aws_route53_zone" "main" {
  name = var.main_zone_name
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}