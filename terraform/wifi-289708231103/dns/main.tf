provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "acm"
  region = var.aws_acm_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "dns"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

resource "aws_route53_zone" "main" {
  name = var.main_zone_name
  tags = local.common_tags
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  providers = {
    aws = aws.acm
  }

  domain_name = var.main_zone_name
  zone_id     = aws_route53_zone.main.zone_id

  subject_alternative_names = [
    "*.${var.main_zone_name}"
  ]

  tags = merge({
    eks      = true
    cloudsdk = true
  }, local.common_tags)
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "zone_name" {
  value = aws_route53_zone.main.name
}

output "certificate_arn" {
  value = module.acm.acm_certificate_arn
}
