data "aws_instance" "quali-cloudshell" {
  instance_id = "i-0c3163fbb5f33b87e"
}

module "backup" {
  source             = "cloudposse/backup/aws"
  version            = "0.10.5"
  namespace          = "quali"
  stage              = "prod"
  name               = "cloudshell"
  tags               = local.common_tags
  backup_resources   = [data.aws_instance.quali-cloudshell.arn]
  schedule           = "cron(0 0 ? * WED,SAT *)"
  cold_storage_after = 3
  delete_after       = 93
}
