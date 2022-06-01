aws_region = "us-east-2" // Ohio

vpc_cidr = "10.10.0.0/16"

env = "main"

project = "wlan"

org = "tip"

node_group_settings = {
  max_capacity  = 8
  min_capacity  = 0
  instance_type = "c5.xlarge"
  ami_name      = "amazon-eks-node-1.22-v20220526" // you can get the latest one using aws ssm get-parameters-by-path --path /aws/service/eks/optimized-ami/1.22/amazon-linux-2 --query "Parameters[].Name"
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
