# ==============================================================================
# Base Infrastructure - Main Configuration
# ==============================================================================
# Foundation layer: VPC, Security Groups, ECR, S3, KMS, IAM
# This layer must be deployed before app-infrastructure
# ==============================================================================

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"
  count  = var.vpc_config != null ? 1 : 0

  vpc_name           = var.vpc_config.name
  primary_cidr       = var.vpc_config.primary_cidr
  secondary_cidrs    = var.vpc_config.secondary_cidrs
  availability_zones = var.vpc_config.availability_zones
  public_subnets     = var.vpc_config.public_subnets
  private_subnets    = var.vpc_config.private_subnets
  database_subnets   = var.vpc_config.database_subnets
  enable_nat_gateway = var.vpc_config.enable_nat_gateway
  single_nat_gateway = var.vpc_config.single_nat_gateway
  enable_flow_logs   = var.vpc_config.enable_flow_logs
  vpc_endpoints      = var.vpc_config.vpc_endpoints

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Groups Module
# -----------------------------------------------------------------------------
module "security_groups" {
  source = "./modules/security-groups"
  count  = var.vpc_config != null ? 1 : 0

  vpc_id              = module.vpc[0].vpc_id
  vpc_cidr            = var.vpc_config.primary_cidr
  environment         = var.environment
  create_alb_sg       = var.security_group_config.create_alb_sg
  create_eks_sg       = var.security_group_config.create_eks_sg
  create_rds_sg       = var.security_group_config.create_rds_sg
  create_lambda_sg    = var.security_group_config.create_lambda_sg
  create_bastion_sg   = var.security_group_config.create_bastion_sg
  allowed_cidr_blocks = var.security_group_config.allowed_cidr_blocks

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR Repositories
# -----------------------------------------------------------------------------
module "ecr" {
  source   = "./modules/ecr"
  for_each = var.ecr_repositories

  repository_name      = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push
  encryption_type      = each.value.encryption_type
  lifecycle_policy     = each.value.lifecycle_policy

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------
module "s3" {
  source   = "./modules/s3"
  for_each = var.s3_buckets

  bucket_name         = each.value.name
  versioning_enabled  = each.value.versioning_enabled
  encryption_enabled  = each.value.encryption_enabled
  kms_key_arn         = each.value.use_custom_kms ? module.kms["s3"].key_arn : null
  lifecycle_rules     = each.value.lifecycle_rules
  cors_rules          = each.value.cors_rules
  block_public_access = each.value.block_public_access

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# KMS Keys
# -----------------------------------------------------------------------------
module "kms" {
  source   = "./modules/kms"
  for_each = var.kms_keys

  alias_name              = each.value.alias
  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = each.value.enable_key_rotation
  key_usage               = each.value.key_usage
  policy                  = each.value.policy

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"
  count  = var.iam_config != null ? 1 : 0

  environment                    = var.environment
  create_eks_cluster_role        = var.iam_config.create_eks_cluster_role
  create_eks_node_role           = var.iam_config.create_eks_node_role
  create_lambda_execution_role   = var.iam_config.create_lambda_execution_role
  create_rds_monitoring_role     = var.iam_config.create_rds_monitoring_role
  create_github_actions_role     = var.iam_config.create_github_actions_role
  github_actions_oidc_provider   = var.iam_config.github_actions_oidc_provider
  github_actions_allowed_repos   = var.iam_config.github_actions_allowed_repos

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
      Layer       = "base-infrastructure"
    }
  )
}
