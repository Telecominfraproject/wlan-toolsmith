provider "aws" {
  version = ">= 2.63.0"
  region  = var.aws_region
}

module "terraform_state_backend" {
  source         = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=0.26.0"
  name           = "terraform"
  s3_bucket_name = "tip-backups-tfstate"
  attributes     = ["state"]
}

output "remote_state_config" {
  value = <<EOF

terraform {
  required_version = ">= 0.13.3"

  backend "s3" {
    region         = "${var.aws_region}"
    bucket         = "${module.terraform_state_backend.s3_bucket_id}"
    key            = "CHANGE ME!!"
    dynamodb_table = "${module.terraform_state_backend.dynamodb_table_name}"
    encrypt        = true
  }
}
EOF
}