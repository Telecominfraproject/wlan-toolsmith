terraform {
  required_version = ">= 0.13.3"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-backups-tfstate"
    key            = "tip-backup"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}

data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_caller_identity" "current" {}
