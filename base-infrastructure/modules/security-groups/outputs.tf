output "alb_sg_id" {
  description = "ALB security group ID"
  value       = try(aws_security_group.alb[0].id, null)
}

output "eks_sg_id" {
  description = "EKS security group ID"
  value       = try(aws_security_group.eks[0].id, null)
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = try(aws_security_group.rds[0].id, null)
}

output "lambda_sg_id" {
  description = "Lambda security group ID"
  value       = try(aws_security_group.lambda[0].id, null)
}

output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = try(aws_security_group.bastion[0].id, null)
}
