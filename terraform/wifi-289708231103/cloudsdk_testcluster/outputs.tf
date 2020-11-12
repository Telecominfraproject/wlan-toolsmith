output "cluster_autoscaler_role_arn" {
  value = module.cluster_autoscaler_cluster_role.this_iam_role_arn
}

output "alb_ingress_controller_role_arn" {
  value = module.alb_ingress_iam_role.this_iam_role_arn
}

output "external_dns_role_arn" {
  value = module.external_dns_cluster_role.this_iam_role_arn
}

output "vpc_id" {
  value = module.vpc_main.vpc_id
}

output "vpc_private_subnets_ids" {
  value = module.vpc_main.private_subnets
}

output "vpc_private_route_table_ids" {
  value = module.vpc_main.private_route_table_ids
}

output "lb_s3_bucket_logging" {
  value = aws_s3_bucket.alb_logs.id
}
