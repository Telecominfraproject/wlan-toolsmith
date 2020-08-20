aws_region = "us-east-2" // Ohio

vpc_cidr = "10.10.0.0/16"

env = "main"

project = "wlan"

org = "tip"

node_group_settings = {
  max_capacity  = 4
  min_capacity  = 1
  instance_type = "m5.large"
}

cluster_version = "1.17"

eks_admin_roles = ["AWSReservedSSO_SystemAdministrator_622371b0ceece6f8"]