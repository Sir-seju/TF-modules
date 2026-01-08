# ==============================================================================
# Application Infrastructure Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "base_state_bucket" {
  description = "S3 bucket for base infrastructure state"
  type        = string
}

variable "base_state_key" {
  description = "S3 key for base infrastructure state"
  type        = string
}

# -----------------------------------------------------------------------------
# EKS Configuration
# -----------------------------------------------------------------------------
variable "eks_config" {
  description = "EKS cluster configuration"
  type = object({
    cluster_name    = string
    cluster_version = optional(string, "1.31")
    enable_irsa     = optional(bool, true)
    cluster_endpoint_public_access = optional(bool, false)
    node_groups = optional(map(object({
      instance_types = list(string)
      min_size       = number
      max_size       = number
      desired_size   = number
      capacity_type  = optional(string, "ON_DEMAND")
      disk_size      = optional(number, 50)
      labels         = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
    })), {})
  })
  default = null
}

# -----------------------------------------------------------------------------
# Aurora Configuration
# -----------------------------------------------------------------------------
variable "aurora_clusters" {
  description = "Map of Aurora clusters"
  type = map(object({
    cluster_identifier = string
    engine             = optional(string, "aurora-postgresql")
    engine_version     = optional(string, "15.4")
    engine_mode        = optional(string, "provisioned")
    instance_class     = optional(string, "db.serverless")
    instance_count     = optional(number, 1)
    database_name      = string
    master_username    = optional(string, "admin")
    serverlessv2_min_capacity = optional(number, 0.5)
    serverlessv2_max_capacity = optional(number, 4)
    backup_retention_period   = optional(number, 7)
    deletion_protection       = optional(bool, true)
    skip_final_snapshot       = optional(bool, false)
    storage_encrypted         = optional(bool, true)
    kms_key_id                = optional(string, null)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# ALB Configuration
# -----------------------------------------------------------------------------
variable "alb_config" {
  description = "ALB configuration"
  type = object({
    name            = string
    certificate_arn = optional(string, null)
    idle_timeout    = optional(number, 60)
    access_logs_bucket = optional(string, null)
    target_groups = optional(map(object({
      port              = number
      protocol          = optional(string, "HTTP")
      target_type       = optional(string, "ip")
      health_check_path = optional(string, "/health")
    })), {})
    listener_rules = optional(list(object({
      priority         = number
      host_header      = optional(list(string), null)
      path_pattern     = optional(list(string), null)
      target_group_key = string
    })), [])
  })
  default = null
}

# -----------------------------------------------------------------------------
# Lambda Configuration
# -----------------------------------------------------------------------------
variable "lambda_functions" {
  description = "Map of Lambda functions"
  type = map(object({
    function_name   = string
    handler         = string
    runtime         = string
    timeout         = optional(number, 30)
    memory_size     = optional(number, 256)
    source_path     = string
    vpc_enabled     = optional(bool, false)
    environment_variables = optional(map(string), {})
    log_retention_days    = optional(number, 14)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Cognito Configuration
# -----------------------------------------------------------------------------
variable "cognito_config" {
  description = "Cognito User Pool configuration"
  type = object({
    user_pool_name           = string
    username_attributes      = optional(list(string), ["email"])
    auto_verified_attributes = optional(list(string), ["email"])
    mfa_configuration        = optional(string, "OPTIONAL")
    deletion_protection      = optional(string, "INACTIVE")
    password_policy = optional(object({
      minimum_length    = optional(number, 8)
      require_lowercase = optional(bool, true)
      require_uppercase = optional(bool, true)
      require_numbers   = optional(bool, true)
      require_symbols   = optional(bool, true)
    }), {})
    schema_attributes = optional(list(object({
      name                = string
      attribute_data_type = string
      mutable             = optional(bool, true)
      required            = optional(bool, false)
      string_length_min   = optional(number, 0)
      string_length_max   = optional(number, 2048)
    })), [])
    clients = optional(list(object({
      name                = string
      generate_secret     = optional(bool, false)
      explicit_auth_flows = optional(list(string), ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
    })), [])
  })
  default = null
}
