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
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

resource "aws_s3_bucket" "openwifi-core-dumps" {
  bucket = "openwifi-core-dumps"
  tags   = local.common_tags
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
