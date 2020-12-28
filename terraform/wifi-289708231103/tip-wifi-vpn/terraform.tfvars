aws_region = "us-east-2"

vpn_endpoint_ip = "209.249.227.25"

nrg_vpn_endpoint_ip = "163.114.132.128"

vpn_endpoint_cidr = "100.97.55.0/24"

sns_alarm_subscriptions = [
  {
    protocol = "email",
    endpoint = "tip-alerts@opsfleet.com"
  },
  {
    protocol = "email",
    endpoint = "tipdevops@launchcg.com"
  },
]
