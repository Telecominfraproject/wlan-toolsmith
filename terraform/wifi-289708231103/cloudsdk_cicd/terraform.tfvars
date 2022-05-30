aws_region = "us-east-2" // Ohio

vpc_cidr = "10.10.0.0/16"

env = "main"

project = "wlan"

org = "tip"

node_group_settings = {
  max_capacity  = 8
  min_capacity  = 0
  instance_type = "c5.xlarge"
  ami_name      = "amazon-eks-node-1.20-v20211109"
}

spot_instance_types = ["m4.large", "m5.large", "m5a.large"]

cluster_version = "1.22"

eks_admin_roles = ["AWSReservedSSO_SystemAdministrator_622371b0ceece6f8", "atlantis-ecs_task_execution"]

base_domain = "lab.wlan.tip.build"

deployment = "cicd"

eks_access_users = [
  "gha-wlan-testing",
  "gha-wlan-test-bss",
  "gha-toolsmith",
  "gha-wlan-cloud-helm",
  "quali",
]

eks_access_users_with_kms_access = [
  "gha-wlan-test-bss",
  "gha-toolsmith",
]
