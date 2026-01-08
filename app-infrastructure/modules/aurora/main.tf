# ==============================================================================
# Aurora Serverless v2 Module
# ==============================================================================

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
  engine             = var.engine
  engine_version     = var.engine_version
  engine_mode        = var.engine_mode

  database_name   = var.database_name
  master_username = var.master_username
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final"

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.instance_class == "db.serverless" ? [1] : []
    content {
      min_capacity = var.serverlessv2_min_capacity
      max_capacity = var.serverlessv2_max_capacity
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [master_password]
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.cluster_identifier}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version

  publicly_accessible = false
  auto_minor_version_upgrade = true

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  tags = var.tags
}
