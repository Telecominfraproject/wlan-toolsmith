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

variable "atlantis_github_user_token" {
  description = "PAT for Github user that will be used by Atlantis"
  type        = string
}

variable "allowed_repos" {
  description = "List of repos that Atlantis will watch"
  type        = list(string)
}
