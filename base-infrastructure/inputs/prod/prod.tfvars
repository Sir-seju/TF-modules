# ==============================================================================
# Production Environment Configuration
# ==============================================================================

environment = "prod"
aws_region  = "us-east-1"

tags = {
  Project       = "enterprise-platform"
  CostCenter    = "production"
  Owner         = "platform-team"
  Compliance    = "SOC2"
  DataClass     = "sensitive"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
vpc_config = {
  name         = "prod-vpc"
  primary_cidr = "10.2.0.0/16"
  secondary_cidrs = ["100.64.0.0/16"] # K8s pod CIDR
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  public_subnets = [
    "10.2.1.0/24",
    "10.2.2.0/24",
    "10.2.3.0/24"
  ]

  private_subnets = [
    "10.2.11.0/24",
    "10.2.12.0/24",
    "10.2.13.0/24"
  ]

  database_subnets = [
    "10.2.21.0/24",
    "10.2.22.0/24",
    "10.2.23.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = false # Full HA for production
  enable_flow_logs   = true

  vpc_endpoints = {
    s3 = {
      service = "s3"
      type    = "Gateway"
    }
    dynamodb = {
      service = "dynamodb"
      type    = "Gateway"
    }
    ecr_api = {
      service             = "ecr.api"
      type                = "Interface"
      private_dns_enabled = true
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      type                = "Interface"
      private_dns_enabled = true
    }
    logs = {
      service             = "logs"
      type                = "Interface"
      private_dns_enabled = true
    }
    secretsmanager = {
      service             = "secretsmanager"
      type                = "Interface"
      private_dns_enabled = true
    }
    kms = {
      service             = "kms"
      type                = "Interface"
      private_dns_enabled = true
    }
  }
}

# -----------------------------------------------------------------------------
# Security Group Configuration
# -----------------------------------------------------------------------------
security_group_config = {
  create_alb_sg     = true
  create_eks_sg     = true
  create_rds_sg     = true
  create_lambda_sg  = true
  create_bastion_sg = true
  allowed_cidr_blocks = ["10.0.0.0/8"]
}

# -----------------------------------------------------------------------------
# ECR Repositories
# -----------------------------------------------------------------------------
ecr_repositories = {
  api = {
    name                 = "prod/api"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "KMS"
    lifecycle_policy = {
      max_image_count      = 50
      expire_untagged_days = 30
    }
  }
  frontend = {
    name                 = "prod/frontend"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "KMS"
    lifecycle_policy = {
      max_image_count      = 50
      expire_untagged_days = 30
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------
s3_buckets = {
  artifacts = {
    name               = "prod-artifacts-bucket"
    versioning_enabled = true
    use_custom_kms     = true
    lifecycle_rules = [{
      id          = "archive-old-versions"
      enabled     = true
      noncurrent_expiration_days = 365
      transition = [{
        days          = 90
        storage_class = "STANDARD_IA"
      }]
    }]
  }
}

# -----------------------------------------------------------------------------
# KMS Keys
# -----------------------------------------------------------------------------
kms_keys = {
  s3 = {
    alias       = "prod-s3-key"
    description = "KMS key for S3 bucket encryption"
  }
  rds = {
    alias       = "prod-rds-key"
    description = "KMS key for RDS encryption"
  }
  ecr = {
    alias       = "prod-ecr-key"
    description = "KMS key for ECR encryption"
  }
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------
iam_config = {
  create_eks_cluster_role      = true
  create_eks_node_role         = true
  create_lambda_execution_role = true
  create_rds_monitoring_role   = true
  create_github_actions_role   = true
  github_actions_allowed_repos = ["your-org/your-repo"]
}
