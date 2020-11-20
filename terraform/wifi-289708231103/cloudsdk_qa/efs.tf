resource "aws_security_group" "efs" {
  name        = "${var.org}-${var.project}-${var.env}-efs"
  description = "${var.org}-${var.project}-${var.env}-efs"
  vpc_id      = module.vpc_main.vpc_id

  tags = {
    Name        = "${var.org}-${var.project}-${var.env}"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_security_group_rule" "efs_ingress" {
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = module.eks.worker_security_group_id
}

resource "aws_efs_file_system" "default" {
  creation_token = "${var.org}-${var.project}-${var.env}-default"

  tags = {
    Name        = "${var.org}-${var.project}-${var.env}-default"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_efs_mount_target" "default" {
  for_each        = toset(module.vpc_main.private_subnets)
  file_system_id  = aws_efs_file_system.default.id
  subnet_id       = each.key
  security_groups = [aws_security_group.efs.id]
}
