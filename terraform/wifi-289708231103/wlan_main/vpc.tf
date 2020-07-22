module "vpc_main" {
  source               = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.33.0"
  name                 = "${var.org}-${var.project}-${var.env}"
  cidr                 = var.vpc_cidr
  azs                  = [for az in var.az : format("%s%s", var.aws_region, az)]
  public_subnets       = [for az in var.az : cidrsubnet(var.vpc_cidr, 8, index(var.az, az))]
  private_subnets      = [for az in var.az : cidrsubnet(var.vpc_cidr, 8, index(var.az, az) + 10)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}