provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-org-tfstate"
    key            = "tip-sops"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "aws_caller_identity" "current" {}
