module "vpc_main" {
  source               = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.33.0"
  name                 = "${var.org}-${var.project}-${var.env}"
  cidr                 = var.vpc_cidr
  azs                  = [for az in var.az : format("%s%s", var.aws_region, az)]
  public_subnets       = [cidrsubnet(var.vpc_cidr, 9, 0), cidrsubnet(var.vpc_cidr, 9, 1), cidrsubnet(var.vpc_cidr, 9, 2)]
  private_subnets      = [cidrsubnet(var.vpc_cidr, 9, 10), cidrsubnet(var.vpc_cidr, 9, 11), cidrsubnet(var.vpc_cidr, 9, 12)]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}