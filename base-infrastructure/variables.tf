# ==============================================================================
# Base Infrastructure Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    name               = string
    primary_cidr       = string
    secondary_cidrs    = optional(list(string), [])
    availability_zones = list(string)
    public_subnets     = list(string)
    private_subnets    = list(string)
    database_subnets   = optional(list(string), [])
    enable_nat_gateway = optional(bool, true)
    single_nat_gateway = optional(bool, false)
    enable_flow_logs   = optional(bool, true)
    vpc_endpoints = optional(map(object({
      service             = string
      type                = string
      private_dns_enabled = optional(bool, true)
    })), {})
  })
  default = null
}

# -----------------------------------------------------------------------------
# Security Group Configuration
# -----------------------------------------------------------------------------
variable "security_group_config" {
  description = "Security group configuration"
  type = object({
    create_alb_sg       = optional(bool, true)
    create_eks_sg       = optional(bool, true)
    create_rds_sg       = optional(bool, true)
    create_lambda_sg    = optional(bool, true)
    create_bastion_sg   = optional(bool, false)
    allowed_cidr_blocks = optional(list(string), [])
  })
  default = {
    create_alb_sg    = true
    create_eks_sg    = true
    create_rds_sg    = true
    create_lambda_sg = true
    create_bastion_sg = false
  }
}

# -----------------------------------------------------------------------------
# ECR Configuration
# -----------------------------------------------------------------------------
variable "ecr_repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    encryption_type      = optional(string, "AES256")
    lifecycle_policy = optional(object({
      max_image_count    = optional(number, 30)
      expire_untagged_days = optional(number, 14)
    }), null)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# S3 Configuration
# -----------------------------------------------------------------------------
variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    name                = string
    versioning_enabled  = optional(bool, true)
    encryption_enabled  = optional(bool, true)
    use_custom_kms      = optional(bool, false)
    block_public_access = optional(bool, true)
    lifecycle_rules = optional(list(object({
      id                       = string
      enabled                  = bool
      prefix                   = optional(string, "")
      expiration_days          = optional(number)
      noncurrent_expiration_days = optional(number)
      transition = optional(list(object({
        days          = number
        storage_class = string
      })), [])
    })), [])
    cors_rules = optional(list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      max_age_seconds = optional(number, 3000)
    })), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# KMS Configuration
# -----------------------------------------------------------------------------
variable "kms_keys" {
  description = "Map of KMS keys to create"
  type = map(object({
    alias                   = string
    description             = string
    deletion_window_in_days = optional(number, 30)
    enable_key_rotation     = optional(bool, true)
    key_usage               = optional(string, "ENCRYPT_DECRYPT")
    policy                  = optional(string, null)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------
variable "iam_config" {
  description = "IAM roles and policies configuration"
  type = object({
    create_eks_cluster_role      = optional(bool, true)
    create_eks_node_role         = optional(bool, true)
    create_lambda_execution_role = optional(bool, true)
    create_rds_monitoring_role   = optional(bool, true)
    create_github_actions_role   = optional(bool, false)
    github_actions_oidc_provider = optional(string, null)
    github_actions_allowed_repos = optional(list(string), [])
  })
  default = null
}
