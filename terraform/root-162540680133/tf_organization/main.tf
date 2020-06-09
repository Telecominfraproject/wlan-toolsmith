terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket = "tfstate-20200529173901447300000001"
    key    = "organization"
    region = "us-east-1"
  }
}

provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}
