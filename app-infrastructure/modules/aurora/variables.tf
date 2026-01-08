variable "cluster_identifier" {
  description = "Cluster identifier"
  type        = string
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "15.4"
}

variable "engine_mode" {
  description = "Engine mode"
  type        = string
  default     = "provisioned"
}

variable "instance_class" {
  description = "Instance class"
  type        = string
  default     = "db.serverless"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "serverlessv2_min_capacity" {
  description = "Serverless v2 min capacity"
  type        = number
  default     = 0.5
}

variable "serverlessv2_max_capacity" {
  description = "Serverless v2 max capacity"
  type        = number
  default     = 4
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatch logs to export"
  type        = list(string)
  default     = ["postgresql"]
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "Monitoring role ARN"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
