//resource "aws_alb" "cloudsdk_portal" {
//  name                             = "${var.deployment}-portal"
//  internal                         = false
//  security_groups                  = [aws_security_group.cloudsdk_lb.id]
//  enable_cross_zone_load_balancing = true
//  subnets                          = module.vpc_main.public_subnets
//  enable_deletion_protection       = false
//  idle_timeout                     = 30
//  tags                             = local.tags
//
//  //  access_logs {
//  //    bucket  = aws_s3_bucket.alb_logs.id
//  //    prefix  = "${var.deployment}-portal"
//  //    enabled = true
//  //  }
//}
//
//resource "aws_alb_target_group" "cloudsdk_portal" {
//  name                 = "${var.deployment}-portal"
//  port                 = var.service_ingress["portal"]["internal_port"]
//  protocol             = var.service_ingress["portal"]["internal_protocol"]
//  vpc_id               = module.vpc_main.vpc_id
//  deregistration_delay = 20
//  proxy_protocol_v2    = false
//
//  health_check {
//    path                = var.service_ingress["portal"]["healthcheck_path"]
//    interval            = 30
//    protocol            = var.service_ingress["portal"]["internal_protocol"]
//    matcher             = "200"
//    timeout             = 5
//    healthy_threshold   = 2
//    unhealthy_threshold = 2
//    port                = var.service_ingress["portal"]["internal_port"]
//  }
//
//  tags = local.tags
//}
//
//resource "aws_autoscaling_attachment" "cloudsdk_portal" {
//  for_each               = toset(module.eks.workers_asg_names)
//  autoscaling_group_name = each.key
//  alb_target_group_arn   = aws_alb_target_group.cloudsdk_portal.arn
//}
//
//resource "aws_alb_listener" "cloudsdk_portal_http" {
//  load_balancer_arn = aws_alb.cloudsdk_portal.arn
//  port              = "80"
//  protocol          = "HTTP"
//
//  default_action {
//    type = "redirect"
//
//    redirect {
//      protocol    = var.service_ingress["portal"]["external_protocol"]
//      status_code = "HTTP_301"
//      port        = var.service_ingress["portal"]["external_port"]
//    }
//  }
//}
//
//resource "aws_alb_listener" "cloudsdk_portal_https" {
//  load_balancer_arn = aws_alb.cloudsdk_portal.arn
//  port              = var.service_ingress["portal"]["external_port"]
//  protocol          = var.service_ingress["portal"]["external_protocol"]
//  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
//  certificate_arn   = aws_acm_certificate.cloudsdk.arn
//
//  default_action {
//    target_group_arn = aws_alb_target_group.cloudsdk_portal.arn
//    type             = "forward"
//  }
//}
//
//resource "aws_security_group_rule" "cloudsdk_portal" {
//  security_group_id        = module.eks.worker_security_group_id
//  from_port                = var.service_ingress["portal"]["internal_port"]
//  to_port                  = var.service_ingress["portal"]["internal_port"]
//  protocol                 = "TCP"
//  source_security_group_id = aws_security_group.cloudsdk_lb.id
//  type                     = "ingress"
//}
//
//resource "aws_route53_record" "cloudsdk_portal" {
//  name            = format("wlan-ui.%s.%s", var.deployment, var.base_domain)
//  type            = "A"
//  zone_id         = aws_route53_zone.cloudsdk.zone_id
//  allow_overwrite = true
//  alias {
//    name                   = aws_alb.cloudsdk_portal.dns_name
//    zone_id                = aws_alb.cloudsdk_portal.zone_id
//    evaluate_target_health = true
//  }
//  lifecycle {
//    ignore_changes = [alias]
//  }
//}

//resource "aws_route53_record" "cloudsdk_portal" {
//  name            = format("wlan-ui.%s.%s", var.deployment, var.base_domain)
//  type            = "A"
//  zone_id         = aws_route53_zone.cloudsdk.zone_id
//  allow_overwrite = true
//  alias {
//    name                   = data.aws_lb.main.dns_name
//    zone_id                = data.aws_lb.main.zone_id
//    evaluate_target_health = true
//  }
//  //  lifecycle {
//  //    ignore_changes = [alias]
//  //  }
//}

output "ui_url" {
  value = format("https://wlan-ui.%s.%s", var.deployment, var.base_domain)
}