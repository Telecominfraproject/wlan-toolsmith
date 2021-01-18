aws_region = "us-east-2" // Ohio

vpc_cidr = "10.10.0.0/16"

env = "main"

project = "wlan"

org = "tip"

node_group_settings = {
  max_capacity  = 4
  min_capacity  = 1
  instance_type = "c5.xlarge"
  ami_name      = "amazon-eks-node-1.18-v20201007"
}

spot_instance_types = ["m4.large", "m5.large", "m5a.large", "t2.large", "t3.large", "t3a.large"]

cluster_version = "1.18"

eks_admin_roles = ["AWSReservedSSO_SystemAdministrator_622371b0ceece6f8"]

base_domain = "lab.wlan.tip.build"

deployment = "cicd"
