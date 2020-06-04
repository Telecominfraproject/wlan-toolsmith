resource "aws_security_group" "fargate_repo_backup" {
  name_prefix = "fargate-repo-backup-"
  description = "Fargate task for repo backup"
  vpc_id      = data.aws_vpc.default.id
  tags        = var.tags
}

resource "aws_security_group_rule" "fargate_repo_backup_egress" {
  description       = "Allow all"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.fargate_repo_backup.id
}