resource "aws_ecr_repository" "repo_backup" {
  name = "repo-backup"
}

output "repo_backup_ecr" {
  value = aws_ecr_repository.repo_backup.repository_url
}