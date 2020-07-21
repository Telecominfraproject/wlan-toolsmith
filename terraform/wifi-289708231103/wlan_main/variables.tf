variable "aws_region" {
  description = "AWS zone"
  type        = string
}

variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "az" {
  default = ["a", "b", "c"]
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "org" {
  description = "Organization name"
  type        = string
}

variable "root_org_account" {
  description = "Root org account id"
  type        = string
  default     = "162540680133"
}