resource "aws_route53_zone" "testdeployment" {
  name = "testdeployment.${var.domain}"
}

resource "aws_route53_record" "aws_route53_zone_testdeployment_main_glue" {
  allow_overwrite = true
  name            = "testdeployment.${var.domain}"
  ttl             = 60
  type            = "NS"
  zone_id         = data.terraform_remote_state.route_53.outputs.zone_id
  records         = aws_route53_zone.testdeployment.name_servers
}

output "aws_route53_zone_testdeployment" {
  value = aws_route53_zone.testdeployment.id
}