variable "aws_region" {}

variable "vpn_endpoint_ip" {
  description = "IP address of the VPN endpoint connecting to AWS"
  type        = string
}

variable "vpn_endpoint_cidr" {
  description = "Subnet behind the VPN endpoint $vpn_endpoint_ip"
  type        = string
}

variable "nrg_vpn_endpoint_ip" {
  description = "IP address of the VPN endpoint connecting to AWS"
  type        = string
}

variable "sns_alarm_subscriptions" {
  description = "SNS VPN alarm subscriptions"
  type        = set(map(string))
}
