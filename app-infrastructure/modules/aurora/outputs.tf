output "cluster_id" {
  description = "Cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Cluster reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Cluster port"
  value       = aws_rds_cluster.this.port
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.this.master_username
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.this.database_name
}
