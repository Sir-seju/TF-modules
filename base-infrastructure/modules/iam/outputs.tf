output "eks_cluster_role_arn" {
  description = "EKS cluster role ARN"
  value       = try(aws_iam_role.eks_cluster[0].arn, null)
}

output "eks_cluster_role_name" {
  description = "EKS cluster role name"
  value       = try(aws_iam_role.eks_cluster[0].name, null)
}

output "eks_node_role_arn" {
  description = "EKS node role ARN"
  value       = try(aws_iam_role.eks_node[0].arn, null)
}

output "eks_node_role_name" {
  description = "EKS node role name"
  value       = try(aws_iam_role.eks_node[0].name, null)
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = try(aws_iam_role.lambda_execution[0].arn, null)
}

output "lambda_execution_role_name" {
  description = "Lambda execution role name"
  value       = try(aws_iam_role.lambda_execution[0].name, null)
}

output "rds_monitoring_role_arn" {
  description = "RDS monitoring role ARN"
  value       = try(aws_iam_role.rds_monitoring[0].arn, null)
}

output "github_actions_role_arn" {
  description = "GitHub Actions role ARN"
  value       = try(aws_iam_role.github_actions[0].arn, null)
}
