# Abstract

This repo provides a code that deploy AWS infrastructure using Terraform on AWS to perform daily backups of github repositiories to S3 bucket.

# Installation

1. Install terraform https://www.terraform.io/downloads.html.

2. Configure AWS access https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html.

## First time setup

1. Cd to `remote_state_tf` directory and run `terraform init` followed by `terraform apply` in order to create AWS S3 bucket storing terraform state.

2. Cd to `tf` directory and run `terraform init` followed by `terraform apply` which creates AWS Step Function, IAM roles, ECS cluster etc.

3. Cd to `build_image`, execute `build_docker_image.sh` script which builds docker image and pushes it to AWS ECR.

4. Subscribe necessary emails to SNS `arn:aws:sns:<region>:<account id>:repo_backup`.

5. Update `github-token` key in SSM parameter store with valid Github API key at https://console.aws.amazon.com/systems-manager/parameters/.

## Updates to the backup code

All backup logic is stored in `build_image` directory, mainly in `build_image/entrypoint_repo_backup.sh`. Once the code is updated, execute `build_docker_image.sh` script which builds docker image and pushes it to AWS ECR.

## Updates to the terraform code

IAM permissions, S3 bucket name, gihub token, github organization name, blacklisted repo list, backup schedule are passed as environment variables to ECS task and are managed by terraform (`tf/terraform.tfvars`). Once terraform code in `tf` directory is updated, execute `terraform apply` in order to apply the changes.

As an example, if you need to change S3 bucket name, perform the following steps:

1. Cd into `tf` directory, run `terraform state rm aws_s3_bucket.repo_backup` and `terraform state rm aws_s3_bucket_public_access_block.repo_backup`.

2. Update S3 bucket name - `s3_bucket_backup_name` variable in `tf/terraform.tfvars`.

3. Run `terraform apply`.

4. Copy the objects from old to new bucket https://aws.amazon.com/premiumsupport/knowledge-center/move-objects-s3-bucket/.

5. Cleanup old bucket `aws s3 rm s3://bucket-name --recursive` (see more at https://docs.aws.amazon.com/AmazonS3/latest/dev/delete-or-empty-bucket.html).

6. Delete old bucket via AWS S3 console.