provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}

resource "aws_s3_bucket" "tfstate" {
  bucket_prefix = "tfstate-"
  acl           = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "tfstate_s3" {
  value = aws_s3_bucket.tfstate.id
}
