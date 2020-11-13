resource "aws_lb" "cloudsdk_gwcontroller" {
  name                             = "${var.deployment}-gwcontroller"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true
  subnets                          = module.vpc_main.public_subnets
  enable_deletion_protection       = false
  idle_timeout                     = 30
  tags                             = local.tags
}

resource "aws_lb_target_group" "cloudsdk_gwcontroller" {
  name                 = "${var.deployment}-gwcontroller"
  port                 = var.service_ingress["gwcontroller"]["internal_port"]
  protocol             = var.service_ingress["gwcontroller"]["internal_protocol"]
  vpc_id               = module.vpc_main.vpc_id
  deregistration_delay = 20
  proxy_protocol_v2    = false

  health_check {
    interval            = 30
    protocol            = var.service_ingress["gwcontroller"]["internal_protocol"]
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "traffic-port"
  }

  tags = local.tags
}

resource "aws_autoscaling_attachment" "cloudsdk_gwcontroller" {
  for_each               = toset(module.eks.workers_asg_names)
  autoscaling_group_name = each.key
  alb_target_group_arn   = aws_lb_target_group.cloudsdk_gwcontroller.arn
}

resource "aws_lb_listener" "cloudsdk_gwcontroller" {
  load_balancer_arn = aws_lb.cloudsdk_gwcontroller.arn
  port              = var.service_ingress["gwcontroller"]["external_port"]
  protocol          = var.service_ingress["gwcontroller"]["external_protocol"]

  default_action {
    target_group_arn = aws_lb_target_group.cloudsdk_gwcontroller.arn
    type             = "forward"
  }
}

resource "aws_security_group_rule" "cloudsdk_gwcontroller" {
  security_group_id = module.eks.worker_security_group_id
  from_port         = var.service_ingress["gwcontroller"]["internal_port"]
  to_port           = var.service_ingress["gwcontroller"]["internal_port"]
  protocol          = "TCP"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_route53_record" "cloudsdk_gwcontroller" {
  name            = format("opensync-controller.%s.%s", var.deployment, var.base_domain)
  type            = "A"
  zone_id         = aws_route53_zone.cloudsdk.zone_id
  allow_overwrite = true
  alias {
    name                   = aws_lb.cloudsdk_gwcontroller.dns_name
    zone_id                = aws_lb.cloudsdk_gwcontroller.zone_id
    evaluate_target_health = true
  }
}