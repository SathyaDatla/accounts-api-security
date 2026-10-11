output "database_endpoint" {
  value       = aws_db_instance.accounts.address
  description = "Private database endpoint; sensitive data remains in AWS."
}
output "ecr_repository_url" { value = aws_ecr_repository.accounts_api.repository_url }
