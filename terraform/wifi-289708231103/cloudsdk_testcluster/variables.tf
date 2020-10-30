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
    max_capacity  = 1
    min_capacity  = 1
    instance_type = "t3.small"
    disk_size     = 20
    ami_name      = ""
  }
}

variable "cluster_log_retention_in_days" {
  description = "Cloudwatch logs retention (days)"
  type        = number
  default     = 30
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "eks_admin_roles" {
  description = "List of role names with system:masters permissions on EKS"
  type        = set(string)
  default     = []
}

variable "base_domain" {
  description = "Public domain name"
  type        = string
}

variable "deployment" {
  description = "Deployment name"
  type        = string
}

variable "service_ingress" {
  description = "Load balancer configuration for ELK services"
  type = map(object({
    internal_protocol = string
    internal_port     = number
    external_protocol = string
    external_port     = number
    healthcheck_path  = string
  }))
}