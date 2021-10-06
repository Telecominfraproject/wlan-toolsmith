provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "quali"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}
