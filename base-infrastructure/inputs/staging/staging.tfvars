# ==============================================================================
# Staging Environment Configuration
# ==============================================================================

environment = "staging"
aws_region  = "us-east-1"

tags = {
  Project    = "enterprise-platform"
  CostCenter = "engineering"
  Owner      = "platform-team"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
vpc_config = {
  name         = "staging-vpc"
  primary_cidr = "10.1.0.0/16"
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  public_subnets = [
    "10.1.1.0/24",
    "10.1.2.0/24",
    "10.1.3.0/24"
  ]

  private_subnets = [
    "10.1.11.0/24",
    "10.1.12.0/24",
    "10.1.13.0/24"
  ]

  database_subnets = [
    "10.1.21.0/24",
    "10.1.22.0/24",
    "10.1.23.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = false # HA for staging
  enable_flow_logs   = true

  vpc_endpoints = {
    s3 = {
      service = "s3"
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
    name         = "staging/api"
    scan_on_push = true
    lifecycle_policy = {
      max_image_count      = 20
      expire_untagged_days = 14
    }
  }
  frontend = {
    name         = "staging/frontend"
    scan_on_push = true
    lifecycle_policy = {
      max_image_count      = 20
      expire_untagged_days = 14
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------
s3_buckets = {
  artifacts = {
    name               = "staging-artifacts-bucket"
    versioning_enabled = true
    lifecycle_rules = [{
      id          = "cleanup-old-versions"
      enabled     = true
      noncurrent_expiration_days = 60
    }]
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
