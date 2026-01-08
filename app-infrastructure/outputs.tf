# ==============================================================================
# Application Infrastructure Outputs
# ==============================================================================

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = try(module.eks[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = try(module.eks[0].cluster_arn, null)
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = try(module.eks[0].oidc_provider_arn, null)
}

# Aurora Outputs
output "aurora_cluster_endpoints" {
  description = "Aurora cluster endpoints"
  value       = { for k, v in module.aurora : k => v.cluster_endpoint }
}

output "aurora_cluster_reader_endpoints" {
  description = "Aurora cluster reader endpoints"
  value       = { for k, v in module.aurora : k => v.cluster_reader_endpoint }
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = try(module.alb[0].dns_name, null)
}

output "alb_arn" {
  description = "ALB ARN"
  value       = try(module.alb[0].arn, null)
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = try(module.alb[0].zone_id, null)
}

# Lambda Outputs
output "lambda_function_arns" {
  description = "Lambda function ARNs"
  value       = { for k, v in module.lambda : k => v.function_arn }
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = try(module.cognito[0].user_pool_id, null)
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = try(module.cognito[0].user_pool_arn, null)
}

output "cognito_client_ids" {
  description = "Cognito client IDs"
  value       = try(module.cognito[0].client_ids, {})
}
