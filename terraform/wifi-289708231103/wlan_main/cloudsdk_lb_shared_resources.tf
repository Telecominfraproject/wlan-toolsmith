resource "aws_security_group" "cloudsdk_lb" {
  name        = "cloudsdk-${var.deployment}-lb"
  description = "SG for EKS LBs servicing ${local.cluster_name}/${var.deployment}} EKS cluster"
  vpc_id      = module.vpc_main.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "cloudsdk_lb_egress" {
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  security_group_id = aws_security_group.cloudsdk_lb.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "cloudsdk_lb_ingress_http" {
  for_each          = toset(["80", "443"])
  from_port         = each.key
  to_port           = each.key
  protocol          = "TCP"
  security_group_id = aws_security_group.cloudsdk_lb.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "alb-logs-"
  acl           = "private"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    prefix  = ""
    enabled = true

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    expiration {
      days = 60
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs_policy.json
}

data "aws_iam_policy_document" "alb_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.alb_logs.arn}/*"]

    // Elastic Load Balancing Account ID in us-east-2
    // https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::033677994240:root",
      ]
    }
  }
}

resource "aws_acm_certificate" "cloudsdk" {
  domain_name       = format("%s.%s", var.deployment, var.base_domain)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudsdk_ssl_validation" {
  zone_id = aws_route53_zone.cloudsdk.id
  name    = aws_acm_certificate.cloudsdk.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cloudsdk.domain_validation_options.0.resource_record_type
  ttl     = 600
  records = [
    aws_acm_certificate.cloudsdk.domain_validation_options.0.resource_record_value
  ]
}

resource "aws_route53_zone" "cloudsdk" {
  name = format("%s.%s", var.deployment, var.base_domain)
}

resource "aws_route53_record" "aws_route53_zone_cloudsdk_main_glue" {
  allow_overwrite = true
  name            = format("%s.%s", var.deployment, var.base_domain)
  ttl             = 60
  type            = "NS"
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  records         = aws_route53_zone.cloudsdk.name_servers
}