terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-org-tfstate"
    key            = "tip-org"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}
