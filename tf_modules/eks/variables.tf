variable "aws_region" {
  description = "AWS zone"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "az" {
  default = ["a", "b", "c"]
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

variable "vpc_id" {
  description = "VPC id, will be created if parameter is omitted"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "public_subnets" {
  description = "List of public subnet ids"
  type        = set(string)
  default     = [""]
}

variable "private_subnets" {
  description = "List of private subnet ids"
  type        = set(string)
  default     = [""]
}