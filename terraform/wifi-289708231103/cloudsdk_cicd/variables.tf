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

variable "ssh_key" {
  description = "Default public ssh key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwLEqyg/ob9w7QNLJI2ldpFzQjvjD0Fz/h5Y2Yrl6ijU7Cs4dOCZJonO7L42luV8tHI1kk4rSpEMbNou6HGWZUYvCMB9dyABYEOtc3a0y+psPw/xNHxDIkDzQ868bktFG2DcJqN2Si6t8pjnLikyBVNCmRNQp2JCa71vL1m1LsnQ5BHYzccXlzzpL0C7yWBUSLlv2l83OMveS8ltZPzXkKo5HkbGBBHGSURAyfLmni6Hz//YQX5yMY+ECrzcKxhki17MYm9OU1rVa5b/Yyntl8jYq6ldx2srik9/OfZzB2PY8w/LF915cg0OqWDkCswwStx7Gr2HjXIQLGnFKWS/V342VKKj+ccpCL/QGGOPzquRglTjFlfD5dssAudQPr1x49kaBE9wg9iFspmozT1sMOUt7zqOfpSIxuEv4zTViE63ClP7SDhgFgXeUj4Trje8562YB5D0ChpxbyIhIQd4rm7zEZoq6hR6/HxvdrKKjxYiqsVwgxCrFiH5NoozOUvqM="
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

variable "testing_instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "testing_big_instance_type" {
  type    = string
  default = "m5a.xlarge"
}

variable "spot_instance_types" {
  type    = list(string)
  default = ["t3.small"]
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

variable "eks_access_users" {
  description = "List of IAM users to be created that require EKS access (i.e. GitHub Actions)"
  type        = set(string)
  default     = []
}

variable "eks_access_users_with_kms_access" {
  description = "List of IAM users for users with EKS access to be granted KMS usage privileges"
  type        = set(string)
  default     = []
}

variable "sdk_ports_secure" {
  description = "List of SDK ports that require TLS termination on AWS side"
  type        = set(number)
  default     = []
}

variable "sdk_ports_insecure" {
  description = "List of SDK ports that don't require TLS termination on AWS side"
  type        = set(number)
  default     = []
}
