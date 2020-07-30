aws_region = "us-east-2" // Ohio

vpc_cidr = "10.10.0.0/16"

env = "main"

project = "wlan"

org = "tip"

node_group_settings = {
  desired_capacity = 1
  max_capacity     = 4
  min_capacity     = 1
  instance_type    = "t3.medium"
  disk_size        = 20
}

cluster_version = "1.17"
