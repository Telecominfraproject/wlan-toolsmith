terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket = "tfstate-20200529173901447300000001"
    key    = "repo-backup"
    region = "us-east-1"
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