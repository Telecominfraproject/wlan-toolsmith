aws_region = "us-east-1"

vpc_cidr = "10.21.0.0/16"

env = "testcluster"

project = "wlan"

org = "tip"

node_group_settings = {
  max_capacity  = 4
  min_capacity  = 1
  instance_type = "m5.large"
  ami_name      = "amazon-eks-node-1.17-v20200814"
}

cluster_version = "1.18"

eks_admin_roles = ["AWSReservedSSO_SystemAdministrator_622371b0ceece6f8"]

base_domain = "lab.wlan.tip.build"

deployment = "testcluster"

service_ingress = {
  "filestore" : {
    "external_port" : 443,
    "internal_port" : 30227,
    "external_protocol" : "TCP",
    "internal_protocol" : "TCP",
    "healthcheck_path" : "",
  },
  "graphql" : {
    "external_port" : 443,
    "internal_port" : 30223,
    "external_protocol" : "HTTPS",
    "internal_protocol" : "HTTP",
    "healthcheck_path" : "/graphql",
  },
  "serviceport" : {
    "external_port" : 443,
    "internal_port" : 30251,
    "external_protocol" : "HTTPS",
    "internal_protocol" : "HTTPS",
    "healthcheck_path" : "/ping",
  },
  "portal" : {
    "external_port" : 443,
    "internal_port" : 30280,
    "external_protocol" : "HTTPS",
    "internal_protocol" : "HTTP",
    "healthcheck_path" : "/",
  },
  "gwcontroller" : {
    "external_port" : 6640,
    "internal_port" : 30229,
    "external_protocol" : "TCP",
    "internal_protocol" : "TCP",
    "healthcheck_path" : "",
  },
  "gwredirector" : {
    "external_port" : 6643,
    "internal_port" : 30230,
    "external_protocol" : "TCP",
    "internal_protocol" : "TCP",
    "healthcheck_path" : "",
  },
  "mqtt" : {
    "external_port" : 1883,
    "internal_port" : 30231,
    "external_protocol" : "TCP",
    "internal_protocol" : "TCP",
    "healthcheck_path" : "",
  },
}