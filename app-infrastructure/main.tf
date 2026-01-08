# ==============================================================================
# Application Infrastructure - Main Configuration
# ==============================================================================
# Application layer: EKS, Aurora, ALB, Lambda, Cognito
# Depends on base-infrastructure outputs
# ==============================================================================

# Data source for base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = var.base_state_bucket
    key    = var.base_state_key
    region = var.aws_region
  }
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"
  count  = var.eks_config != null ? 1 : 0

  cluster_name    = var.eks_config.cluster_name
  cluster_version = var.eks_config.cluster_version
  vpc_id          = data.terraform_remote_state.base.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.base.outputs.private_subnet_ids

  cluster_role_arn = data.terraform_remote_state.base.outputs.eks_cluster_role_arn
  node_role_arn    = data.terraform_remote_state.base.outputs.eks_node_role_arn

  node_groups           = var.eks_config.node_groups
  enable_irsa           = var.eks_config.enable_irsa
  cluster_endpoint_public_access = var.eks_config.cluster_endpoint_public_access

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Aurora Database
# -----------------------------------------------------------------------------
module "aurora" {
  source   = "./modules/aurora"
  for_each = var.aurora_clusters

  cluster_identifier = each.value.cluster_identifier
  engine             = each.value.engine
  engine_version     = each.value.engine_version
  engine_mode        = each.value.engine_mode
  instance_class     = each.value.instance_class
  instance_count     = each.value.instance_count

  database_name   = each.value.database_name
  master_username = each.value.master_username

  vpc_id                     = data.terraform_remote_state.base.outputs.vpc_id
  subnet_ids                 = data.terraform_remote_state.base.outputs.database_subnet_ids
  vpc_security_group_ids     = [data.terraform_remote_state.base.outputs.rds_security_group_id]
  db_subnet_group_name       = data.terraform_remote_state.base.outputs.database_subnet_group_name

  serverlessv2_min_capacity = each.value.serverlessv2_min_capacity
  serverlessv2_max_capacity = each.value.serverlessv2_max_capacity

  backup_retention_period = each.value.backup_retention_period
  deletion_protection     = each.value.deletion_protection
  skip_final_snapshot     = each.value.skip_final_snapshot
  storage_encrypted       = each.value.storage_encrypted
  kms_key_id              = each.value.kms_key_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"
  count  = var.alb_config != null ? 1 : 0

  name               = var.alb_config.name
  vpc_id             = data.terraform_remote_state.base.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.base.outputs.public_subnet_ids
  security_group_ids = [data.terraform_remote_state.base.outputs.alb_security_group_id]

  certificate_arn = var.alb_config.certificate_arn
  target_groups   = var.alb_config.target_groups
  listener_rules  = var.alb_config.listener_rules

  access_logs_bucket = var.alb_config.access_logs_bucket
  idle_timeout       = var.alb_config.idle_timeout

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------
module "lambda" {
  source   = "./modules/lambda"
  for_each = var.lambda_functions

  function_name = each.value.function_name
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size

  role_arn    = data.terraform_remote_state.base.outputs.lambda_execution_role_arn
  source_path = each.value.source_path

  vpc_config = each.value.vpc_enabled ? {
    subnet_ids         = data.terraform_remote_state.base.outputs.private_subnet_ids
    security_group_ids = [data.terraform_remote_state.base.outputs.lambda_security_group_id]
  } : null

  environment_variables = each.value.environment_variables
  log_retention_days    = each.value.log_retention_days

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Cognito User Pool
# -----------------------------------------------------------------------------
module "cognito" {
  source = "./modules/cognito"
  count  = var.cognito_config != null ? 1 : 0

  user_pool_name           = var.cognito_config.user_pool_name
  username_attributes      = var.cognito_config.username_attributes
  auto_verified_attributes = var.cognito_config.auto_verified_attributes
  mfa_configuration        = var.cognito_config.mfa_configuration

  password_policy   = var.cognito_config.password_policy
  schema_attributes = var.cognito_config.schema_attributes
  clients           = var.cognito_config.clients

  deletion_protection = var.cognito_config.deletion_protection

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "app-infrastructure"
    }
  )
}
