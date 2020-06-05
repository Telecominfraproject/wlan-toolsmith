resource "aws_s3_bucket" "repo_backup" {
  bucket = var.s3_bucket_backup_name
  acl    = "private"

  versioning {
    enabled = var.s3_bucket_versioning
  }

  lifecycle_rule {
    prefix  = ""
    enabled = true

    transition {
      days          = 7
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      days          = 7
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_expiration {
      days = 8
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

resource "aws_s3_bucket_public_access_block" "repo_backup" {
  bucket                  = aws_s3_bucket.repo_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = data.aws_vpc.default.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  auto_accept     = true
  route_table_ids = data.aws_route_tables.default.ids
}

data "aws_route_tables" "default" {
  vpc_id = data.aws_vpc.default.id
}