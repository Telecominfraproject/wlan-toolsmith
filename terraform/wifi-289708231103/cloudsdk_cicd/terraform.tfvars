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

cluster_version = "1.18"

eks_admin_roles = ["AWSReservedSSO_SystemAdministrator_622371b0ceece6f8"]

base_domain = "lab.wlan.tip.build"

deployment = "cicd"

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
    "internal_port" : 30233,
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

ingress_lb = "a46650fef61b84171825228af3cfc4b2-1416366176.us-east-2.elb.amazonaws.com"