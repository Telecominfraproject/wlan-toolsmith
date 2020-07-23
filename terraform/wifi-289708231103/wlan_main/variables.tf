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
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwLEqyg/ob9w7QNLJI2ldpFzQjvjD0Fz/h5Y2Yrl6ijU7Cs4dOCZJonO7L42luV8tHI1kk4rSpEMbNou6HGWZUYvCMB9dyABYEOtc3a0y+psPw/xNHxDIkDzQ868bktFG2DcJqN2Si6t8pjnLikyBVNCmRNQp2JCa71vL1m1LsnQ5BHYzccXlzzpL0C7yWBUSLlv2l83OMveS8ltZPzXkKo5HkbGBBHGSURAyfLmni6Hz//YQX5yMY+ECrzcKxhki17MYm9OU1rVa5b/Yyntl8jYq6ldx2srik9/OfZzB2PY8w/LF915cg0OqWDkCswwStx7Gr2HjXIQLGnFKWS/V342VKKj+ccpCL/QGGOPzquRglTjFlfD5dssAudQPr1x49kaBE9wg9iFspmozT1sMOUt7zqOfpSIxuEv4zTViE63ClP7SDhgFgXeUj4Trje8562YB5D0ChpxbyIhIQd4rm7zEZoq6hR6/HxvdrKKjxYiqsVwgxCrFiH5NoozOUvqM="
}