resource "aws_ssm_parameter" "github_token" {
  name  = "github-token"
  type  = "SecureString"
  value = "undefined"

  lifecycle {
    ignore_changes = [value]
  }
}