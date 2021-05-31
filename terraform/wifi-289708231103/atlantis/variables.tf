variable "aws_region" {
  description = "AWS region to deploy Atlantis to"
  type        = string
}

variable "atlantis_github_user" {
  description = "Github user that will be used by Atlantis"
  type        = string
}

variable "atlantis_github_organization" {
  description = "Github Organization that Atlantis will use to create the webhooks"
  type        = string
}

variable "repo_whitelist" {
  description = "List of repos that Atlantis is allowed to work with"
  type        = list(string)
}

variable "repo_names" {
  description = "List of repos that will be configured to work with Atlantis"
  type        = list(string)
}

variable "atlantis_policy_arns" {
  description = "List of ARNs of policies that will be attached to Atlantis"
  type        = list(string)
}

variable "default_terraform_version" {
  description = "Default Terraform version that Atlantis will use, see https://www.runatlantis.io/docs/terraform-versions.html#via-atlantis-yaml"
  type        = string
}
