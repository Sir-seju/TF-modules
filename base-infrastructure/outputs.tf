# ==============================================================================
# Base Infrastructure Outputs
# ==============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = try(module.vpc[0].vpc_id, null)
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = try(module.vpc[0].vpc_cidr, null)
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = try(module.vpc[0].public_subnet_ids, [])
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = try(module.vpc[0].private_subnet_ids, [])
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = try(module.vpc[0].database_subnet_ids, [])
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = try(module.vpc[0].nat_gateway_ids, [])
}

output "vpc_endpoint_ids" {
  description = "Map of VPC endpoint IDs"
  value       = try(module.vpc[0].vpc_endpoint_ids, {})
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = try(module.security_groups[0].alb_sg_id, null)
}

output "eks_security_group_id" {
  description = "EKS security group ID"
  value       = try(module.security_groups[0].eks_sg_id, null)
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = try(module.security_groups[0].rds_sg_id, null)
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = try(module.security_groups[0].lambda_sg_id, null)
}

output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = try(module.security_groups[0].bastion_sg_id, null)
}

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = { for k, v in module.ecr : k => v.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = { for k, v in module.ecr : k => v.repository_arn }
}

# -----------------------------------------------------------------------------
# S3 Outputs
# -----------------------------------------------------------------------------
output "s3_bucket_ids" {
  description = "Map of S3 bucket IDs"
  value       = { for k, v in module.s3 : k => v.bucket_id }
}

output "s3_bucket_arns" {
  description = "Map of S3 bucket ARNs"
  value       = { for k, v in module.s3 : k => v.bucket_arn }
}

# -----------------------------------------------------------------------------
# KMS Outputs
# -----------------------------------------------------------------------------
output "kms_key_arns" {
  description = "Map of KMS key ARNs"
  value       = { for k, v in module.kms : k => v.key_arn }
}

output "kms_key_ids" {
  description = "Map of KMS key IDs"
  value       = { for k, v in module.kms : k => v.key_id }
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------
output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = try(module.iam[0].eks_cluster_role_arn, null)
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = try(module.iam[0].eks_node_role_arn, null)
}

output "lambda_execution_role_arn" {
  description = "Lambda execution IAM role ARN"
  value       = try(module.iam[0].lambda_execution_role_arn, null)
}

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = try(module.iam[0].github_actions_role_arn, null)
}
