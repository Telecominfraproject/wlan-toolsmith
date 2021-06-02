terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "atlantis"
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

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}

module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"
  version = "2.38.0"

  name = "atlantis"

  cidr            = "10.20.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]

  route53_zone_name = trimsuffix(data.terraform_remote_state.route_53.outputs.zone_name, ".")


  atlantis_version           = "v0.14.0"
  atlantis_github_user       = var.atlantis_github_user
  atlantis_repo_whitelist    = var.repo_whitelist
  atlantis_github_user_token = data.sops_file.secrets.data["atlantis_github_user_token"]

  policies_arn = var.atlantis_policy_arns

  ecs_fargate_spot = true

  tags = {
    "ManagedBy" = "terraform"
  }

  custom_environment_variables = [
    {
      name  = "ATLANTIS_DEFAULT_TF_VERSION"
      value = var.default_terraform_version
    },
    {
      name  = "ATLANTIS_REPO_CONFIG_JSON"
      value = file("atlantis.json")
    }
  ]

}

module "github_repository_webhook" {
  source = "terraform-aws-modules/atlantis/aws//modules/github-repository-webhook"

  github_organization = var.atlantis_github_organization
  github_token        = data.sops_file.secrets.data["atlantis_github_user_token"]

  atlantis_allowed_repo_names = var.repo_names

  webhook_url    = module.atlantis.atlantis_url_events
  webhook_secret = module.atlantis.webhook_secret
}
