variable "region" {
  default = "us-east-1"
}

variable "vpn_endpoint_ip" {
  description = "IP address of the VPN endpoint connecting to AWS"
  type        = string
}

variable "vpn_endpoint_cidr" {
  description = "Subnet behind the VPN endpoint $vpn_endpoint_ip"
}
