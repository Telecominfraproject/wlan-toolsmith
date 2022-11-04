resource "random_string" "random_suffix" {
  length  = 10
  special = false
  upper   = false
  lower   = true
  number  = false
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "alb-logs-${var.org}-${var.project}-${var.deployment}-${random_string.random_suffix.result}"
  acl    = "private"

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

  tags = merge({
    "Name" : "alb-logs-${var.org}-${var.project}-${var.deployment}-${random_string.random_suffix.result}"
  }, local.common_tags)

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

    // Elastic Load Balancing Account ID https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::127311923021:root", # us-east-1
        "arn:aws:iam::033677994240:root", # us-east-2
      ]
    }
  }
}

resource "aws_acm_certificate" "cloudsdk" {
  domain_name = format("%s.%s", var.deployment, var.base_domain)
  subject_alternative_names = [
    format("*.%s.%s", var.deployment, var.base_domain)
  ]
  validation_method = "DNS"
  tags              = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudsdk_ssl_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudsdk.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  allow_overwrite = true
  records = [
    each.value.record
  ]
}
