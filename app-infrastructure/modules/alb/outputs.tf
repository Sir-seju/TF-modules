output "arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "Target group ARNs"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}
