provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "core-dumps-s3"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}

resource "aws_s3_bucket" "openwifi-core-dumps" {
  bucket = "openwifi-core-dumps"
  tags   = local.common_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "openwifi-core-dumps" {
  bucket = aws_s3_bucket.openwifi-core-dumps.id

  rule {
    id = "core-dumps-retention"
    filter {}
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}

resource "aws_s3_bucket_notification" "s3_eventnotification_slack" {
  bucket = aws_s3_bucket.openwifi-core-dumps.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_eventnotification_slack.arn
    events              = ["s3:ObjectCreated:Put"]
  }

  depends_on = [aws_lambda_permission.s3_eventnotification_slack]
}

resource "aws_iam_role" "s3_eventnotification_slack" {
  name = "s3_eventnotification_slack"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "s3_eventnotification_slack" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_eventnotification_slack.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.openwifi-core-dumps.arn
}

resource "aws_lambda_function" "s3_eventnotification_slack" {
  filename      = "s3_eventnotification_slack.zip"
  function_name = "s3_eventnotification_slack"
  role          = aws_iam_role.s3_eventnotification_slack.arn
  runtime       = "python3.9"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = data.sops_file.secrets.data["slack_webhook_url"]
    }
  }
}

resource "aws_s3_bucket_acl" "openwifi-core-dumps" {
  bucket = aws_s3_bucket.openwifi-core-dumps.id
  acl    = "private"
}

resource "aws_iam_user" "openwifi-core-dump-handler" {
  name = "openwifi-core-dump-handler"
  tags = local.common_tags
}

resource "aws_iam_access_key" "openwifi-core-dump-handler" {
  user = aws_iam_user.openwifi-core-dump-handler.name
}

resource "aws_iam_user_policy" "openwifi-core-dump-handler" {
  name = "openwifi-core-dump-handler"
  user = aws_iam_user.openwifi-core-dump-handler.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.openwifi-core-dumps.arn,
          "${aws_s3_bucket.openwifi-core-dumps.arn}/*"
        ]
      }
    ]
  })
}
