output "user_pool_id" {
  description = "User pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "User pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "User pool endpoint"
  value       = aws_cognito_user_pool.this.endpoint
}

output "client_ids" {
  description = "Client IDs"
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.id }
}
