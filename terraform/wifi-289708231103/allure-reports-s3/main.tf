provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "tip-wifi-tfstate"
    key            = "allure-reports-s3"
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
  bucket = "openwifi-allure-reports"
  acl    = "public-read"
  tags = merge({
    "Name" : "openwifi-allure-reports"
  }, local.common_tags)

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
  name = "allure-reports-uploader"
  tags = local.common_tags
}

resource "aws_iam_access_key" "uploader" {
  user = aws_iam_user.uploader.name
}

resource "aws_iam_user_policy" "uploader" {
  name = "allure-reports-upload"
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
