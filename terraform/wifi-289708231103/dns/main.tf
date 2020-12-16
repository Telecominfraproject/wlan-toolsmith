provider "aws" {
  version = ">= 2.59.0"
  region  = var.aws_region
}

provider "aws" {
  alias   = "acm"
  version = ">= 2.59.0"
  region  = var.aws_acm_region
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

module "acm" {
  providers = {
    aws = aws.acm
  }
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm?ref=v2.9.0"

  domain_name = var.main_zone_name
  zone_id     = aws_route53_zone.main.zone_id

  subject_alternative_names = [
    "*.${var.main_zone_name}"
  ]

  tags = {
    eks      = true
    cloudsdk = true
  }
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "certificate_arn" {
  value = module.acm.this_acm_certificate_arn
}