# Demo instance for WIFI-10153
# TODO increase disk size
resource "aws_instance" "wlan_demo" {
  ami                    = "ami-00399ec92321828f5" # Ubuntu 20.04 amd64
  instance_type          = "t2.xlarge"
  subnet_id              = module.vpc_main.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.wlan.id]
  key_name               = aws_key_pair.dunaev_wifi_3714.id

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
  }

  tags = merge({
    "Name" : "${var.org}-${var.project}-${var.env} demo server (WIFI-10153)"
  }, local.common_tags)
}

resource "aws_eip" "wlan_demo" {
  vpc      = true
  instance = aws_instance.wlan_demo.id
  tags     = local.common_tags
}

# Certificate
data "aws_acm_certificate" "cert_cicd" {
  domain   = "cicd.${data.terraform_remote_state.route_53.outputs.zone_name}"
  statuses = ["ISSUED"]
}

# Load balancers
## NLB to SDK endpoints
resource "aws_lb" "nlb_demo" {
  name                       = "nlb-demo"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = module.vpc_main.public_subnets
  enable_deletion_protection = false
  tags                       = local.common_tags
}

### Secure endpoints
locals {
  sdk_ports_secure = toset([for port in var.sdk_ports_secure : tostring(port)])
}
#target_group
resource "aws_lb_target_group" "nlb_demo_tls" {
  for_each = local.sdk_ports_secure
  name     = "nlb-demo-tls-${each.value}"
  port     = each.value
  protocol = "TLS"
  vpc_id   = module.vpc_main.vpc_id
  health_check {
    port = 16101
  }
}
#target_group_attachment
resource "aws_lb_target_group_attachment" "nlb_demo_tls" {
  for_each         = aws_lb_target_group.nlb_demo_tls
  target_group_arn = each.value.arn
  target_id        = aws_instance.wlan_demo.id
  port             = each.value.port
}
#listener
resource "aws_lb_listener" "nlb_demo_tls" {
  for_each          = aws_lb_target_group.nlb_demo_tls
  load_balancer_arn = aws_lb.nlb_demo.arn
  port              = each.value.port
  protocol          = "TLS"
  certificate_arn   = data.aws_acm_certificate.cert_cicd.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
}

### Insecure endpoints
locals {
  sdk_ports_insecure = toset([for port in var.sdk_ports_insecure : tostring(port)])
}
#target_group
resource "aws_lb_target_group" "nlb_demo_tcp" {
  for_each = local.sdk_ports_insecure
  name     = "nlb-demo-tcp-${each.value}"
  port     = each.value
  protocol = "TCP"
  vpc_id   = module.vpc_main.vpc_id
  health_check {
    port = 16101
  }
}
#target_group_attachment
resource "aws_lb_target_group_attachment" "nlb_demo_tcp" {
  for_each         = aws_lb_target_group.nlb_demo_tcp
  target_group_arn = each.value.arn
  target_id        = aws_instance.wlan_demo.id
  port             = each.value.port
}
#listener
resource "aws_lb_listener" "nlb_demo_tcp" {
  for_each          = aws_lb_target_group.nlb_demo_tcp
  load_balancer_arn = aws_lb.nlb_demo.arn
  port              = each.value.port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
}

## ALB
resource "aws_security_group" "ingress_http_https_allow" {
  name        = "ingress_http_https_allow"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = module.vpc_main.vpc_id

  ingress {
    description      = "HTTP from outside"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from outside"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ingress_http_https_allow"
  }
}
resource "aws_lb" "alb_demo" {
  name                       = "alb-demo"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ingress_http_https_allow.id]
  subnets                    = module.vpc_main.public_subnets
  enable_deletion_protection = false
  tags                       = local.common_tags
}
resource "aws_lb_listener" "alb_https_demo" {
  load_balancer_arn = aws_lb.alb_demo.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert_cicd.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Host rule not found"
      status_code  = "404"
    }
  }
}
resource "aws_lb_listener" "alb_http_demo" {
  load_balancer_arn = aws_lb.alb_demo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
## ALB to OWGW WebUI
#target groups
resource "aws_lb_target_group" "alb_owgwui_https_demo" {
  name     = "alb-owgwui-https-demo"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc_main.vpc_id
  health_check {
    port = 16101
  }
}
#target_group_attachment
resource "aws_lb_target_group_attachment" "alb_owgwui_https_demo" {
  target_group_arn = aws_lb_target_group.alb_owgwui_https_demo.arn
  target_id        = aws_instance.wlan_demo.id
  port             = 443
}
#listener_rule
resource "aws_lb_listener_rule" "alb_owgwui_https_demo" {
  listener_arn = aws_lb_listener.alb_https_demo.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_owgwui_https_demo.arn
  }

  condition {
    host_header {
      values = ["webui-demo.cicd.${data.terraform_remote_state.route_53.outputs.zone_name}"]
    }
  }
}

## ALB to OWProv WebUI
#target groups
resource "aws_lb_target_group" "alb_owprovui_https_demo" {
  name     = "alb-owprovui-https-demo"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = module.vpc_main.vpc_id
  health_check {
    port = 16101
  }
}
#target_group_attachment
resource "aws_lb_target_group_attachment" "alb_owprovui_https_demo" {
  target_group_arn = aws_lb_target_group.alb_owprovui_https_demo.arn
  target_id        = aws_instance.wlan_demo.id
  port             = 8443
}
#listener_rule
resource "aws_lb_listener_rule" "alb_owprovui_https_demo" {
  listener_arn = aws_lb_listener.alb_https_demo.arn
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_owprovui_https_demo.arn
  }

  condition {
    host_header {
      values = ["provui-demo.cicd.${data.terraform_remote_state.route_53.outputs.zone_name}"]
    }
  }
}

# DNS Records
resource "aws_route53_record" "wlan_demo_instance" {
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  name            = "instance-demo.cicd"
  type            = "A"
  ttl             = 600
  allow_overwrite = true
  records = [
    aws_eip.wlan_demo.public_ip
  ]
}

resource "aws_route53_record" "wlan_demo_sdk" {
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  name            = "sdk-demo.cicd"
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.nlb_demo.dns_name
    zone_id                = aws_lb.nlb_demo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wlan_demo_webui" {
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  name            = "webui-demo.cicd"
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.alb_demo.dns_name
    zone_id                = aws_lb.alb_demo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wlan_demo_provui" {
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  name            = "provui-demo.cicd"
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.alb_demo.dns_name
    zone_id                = aws_lb.alb_demo.zone_id
    evaluate_target_health = true
  }
}

# Outputs
output "wlan_demo_instance" {
  value = aws_eip.wlan_demo.public_ip
}

output "wlan_demo_sdk_fqdn" {
  value = aws_route53_record.wlan_demo_sdk.fqdn
}
output "wlan_demo_webui_fqdn" {
  value = aws_route53_record.wlan_demo_webui.fqdn
}
output "wlan_demo_provui_fqdn" {
  value = aws_route53_record.wlan_demo_provui.fqdn
}
