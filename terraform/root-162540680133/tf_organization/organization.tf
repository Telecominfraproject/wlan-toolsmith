resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "sso.amazonaws.com",
  ]

  feature_set = "ALL"

  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

resource "aws_organizations_account" "wifi" {
  name      = "wifi"
  email     = "wifi-admin@telecominfraproject.com"
  parent_id = aws_organizations_organizational_unit.default.id
}

resource "aws_organizations_account" "cicd" {
  name      = "cicd"
  email     = "cicd-admin@telecominfraproject.com"
  parent_id = aws_organizations_organizational_unit.default.id
}

resource "aws_organizations_organizational_unit" "default" {
  name      = "default"
  parent_id = aws_organizations_organization.org.roots.0.id
}