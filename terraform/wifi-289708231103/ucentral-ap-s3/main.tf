provider "aws" {
  version = ">= 2.59.0"
  region  = var.aws_region
}

terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "ucentral-ap-s3"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "route_53" {
  backend = "s3"

  config = {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "dns"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

locals {
  common_tags = {
    "ManagedBy" = "terraform"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "ucentral-ap-firmware"
  acl    = "public-read"
  tags   = local.common_tags

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
  }

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "ucentral-ap-firmware-logs"
  acl    = "log-delivery-write"
  tags   = local.common_tags
}

resource "aws_s3_bucket_object" "directory_listing" {
  bucket       = aws_s3_bucket.bucket.bucket
  key          = "index.html"
  acl          = "public-read"
  content_type = "text/html"
  content      = <<EOF
  <!-- https://github.com/rufuspollock/s3-bucket-listing -->
  <head>
    <meta charset="UTF-8">
    <!-- add jQuery - if you already have it just ignore this line -->
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
  </head>
  <body>
    <div id="navigation"></div>
    <div id="listing"></div>

    <!-- the JS variables for the listing -->
    <script type="text/javascript">
      var BUCKET_URL = 'https://${aws_s3_bucket.bucket.bucket_regional_domain_name}';
      var EXCLUDE_FILE = 'index.html';
      var S3B_SORT = 'Z2A';
    </script>

    <!-- the JS to the do the listing -->
    <script type="text/javascript" src="https://rufuspollock.github.io/s3-bucket-listing/list.js"></script>
  </body>
  EOF
}

resource "aws_iam_user" "uploader" {
  name = "ucentral-firmware-uploader"
  tags = local.common_tags
}

resource "aws_iam_access_key" "uploader" {
  user = aws_iam_user.uploader.name
}

resource "aws_iam_user_policy" "uploader" {
  name = "ucentral-firmware-upload"
  user = aws_iam_user.uploader.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "firmware_service" {
  name = "ucentral-firmware-service"
  tags = local.common_tags
}

resource "aws_iam_access_key" "firmware_service" {
  user = aws_iam_user.firmware_service.name
}

resource "aws_iam_user_policy" "firmware_" {
  name = "ucentral-firmware-service"
  user = aws_iam_user.firmware_service.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListObjects",
          "s3:WriteObjects"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "firmware_logstash" {
  name = "ucentral-ap-firmware-logstash"
  tags = local.common_tags
}

resource "aws_iam_access_key" "firmware_logstash" {
  user = aws_iam_user.firmware_logstash.name
}

resource "aws_iam_user_policy" "firmware_logstash" {
  user = aws_iam_user.firmware_logstash.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.log_bucket.arn,
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}
