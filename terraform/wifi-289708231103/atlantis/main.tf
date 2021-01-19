terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "atlantis"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "route_53" {
  backend = "s3"

  config = {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "dns"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "~> 2.0"

  name = "atlantis"

  cidr            = "10.20.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]

  route53_zone_name = trimsuffix(data.terraform_remote_state.route_53.outputs.zone_name, ".")

  atlantis_github_user       = var.atlantis_github_user
  atlantis_github_user_token = var.atlantis_github_user_token
  atlantis_repo_whitelist    = var.repo_whitelist

  policies_arn = var.atlantis_policy_arns

  ecs_fargate_spot = true

  tags = {
    "ManagedBy" = "terraform"
  }
}

module "github_repository_webhook" {
  source = "terraform-aws-modules/atlantis/aws//modules/github-repository-webhook"

  github_organization = var.atlantis_github_organization
  github_token        = var.atlantis_github_user_token

  atlantis_allowed_repo_names = var.repo_names

  webhook_url    = module.atlantis.atlantis_url_events
  webhook_secret = module.atlantis.webhook_secret
}
