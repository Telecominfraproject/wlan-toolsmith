resource "aws_alb" "cloudsdk_graphql" {
  name                             = "${var.deployment}-graphql"
  internal                         = false
  security_groups                  = [aws_security_group.cloudsdk_lb.id]
  enable_cross_zone_load_balancing = true
  subnets                          = module.vpc_main.public_subnets
  enable_deletion_protection       = false
  idle_timeout                     = 30
  tags                             = local.tags

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "${var.deployment}-graphql"
    enabled = true
  }
}

resource "aws_alb_target_group" "cloudsdk_graphql" {
  name                 = "${var.deployment}-graphql"
  port                 = var.service_ingress["graphql"]["internal_port"]
  protocol             = var.service_ingress["graphql"]["internal_protocol"]
  vpc_id               = module.vpc_main.vpc_id
  deregistration_delay = 20
  proxy_protocol_v2    = false

  health_check {
    path                = var.service_ingress["graphql"]["healthcheck_path"]
    interval            = 30
    protocol            = var.service_ingress["graphql"]["internal_protocol"]
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = var.service_ingress["graphql"]["internal_port"]
  }

  tags = local.tags
}

resource "aws_autoscaling_attachment" "cloudsdk_graphql" {
  for_each               = toset(module.eks.workers_asg_names)
  autoscaling_group_name = each.key
  alb_target_group_arn   = aws_alb_target_group.cloudsdk_graphql.arn
}

resource "aws_alb_listener" "cloudsdk_graphql_http" {
  load_balancer_arn = aws_alb.cloudsdk_graphql.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = var.service_ingress["graphql"]["external_protocol"]
      status_code = "HTTP_301"
      port        = var.service_ingress["graphql"]["external_port"]
    }
  }
}

resource "aws_alb_listener" "cloudsdk_graphql_https" {
  load_balancer_arn = aws_alb.cloudsdk_graphql.arn
  port              = var.service_ingress["graphql"]["external_port"]
  protocol          = var.service_ingress["graphql"]["external_protocol"]
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.cloudsdk.arn

  default_action {
    target_group_arn = aws_alb_target_group.cloudsdk_graphql.arn
    type             = "forward"
  }
}

resource "aws_security_group_rule" "cloudsdk_graphql" {
  security_group_id        = module.eks.worker_security_group_id
  from_port                = var.service_ingress["graphql"]["internal_port"]
  to_port                  = var.service_ingress["graphql"]["internal_port"]
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.cloudsdk_lb.id
  type                     = "ingress"
}

resource "aws_route53_record" "cloudsdk_graphql" {
  name            = format("wlan-graphql.%s.%s", var.deployment, var.base_domain)
  type            = "A"
  zone_id         = aws_route53_zone.cloudsdk.zone_id
  allow_overwrite = true
  alias {
    name                   = aws_alb.cloudsdk_graphql.dns_name
    zone_id                = aws_alb.cloudsdk_graphql.zone_id
    evaluate_target_health = true
  }
}