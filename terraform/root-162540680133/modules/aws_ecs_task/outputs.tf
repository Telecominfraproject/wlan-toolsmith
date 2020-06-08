output "ecs_execution_role" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.sfn.arn
}

output "ecr_url" {
  value = aws_ecr_repository.main.repository_url
}