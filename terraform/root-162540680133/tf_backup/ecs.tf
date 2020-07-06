resource "aws_ecs_cluster" "automation" {
  name = "automation"
  tags = var.tags
}