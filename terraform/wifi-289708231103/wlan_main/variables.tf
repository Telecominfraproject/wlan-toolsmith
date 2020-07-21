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

variable "node_group_settings" {
  description = "Cluster node group settings"
  type        = map(string)
  default = {
    desired_capacity = 1
    max_capacity     = 1
    min_capacity     = 1
    instance_type    = "t3.small"
    disk_size        = 20
  }
}

variable "cluster_log_retention_in_days" {
  description = "Cloudwatch logs retention (days)"
  type        = number
  default     = 35
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}