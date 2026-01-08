# Enterprise Terraform Infrastructure

Production-grade, modular Terraform infrastructure for deploying enterprise AWS environments. Designed with separation of concerns, multi-environment support, and GitOps best practices.

## Architecture Overview

```
TF-modules/
├── base-infrastructure/        # Foundation layer (deploy first)
│   ├── main.tf                 # Orchestrates base modules
│   ├── variables.tf            # Input variable definitions
│   ├── outputs.tf              # Outputs for app-infrastructure
│   ├── providers.tf            # Provider configuration
│   ├── inputs/                 # Environment-specific configurations
│   │   ├── dev/dev.tfvars
│   │   ├── staging/staging.tfvars
│   │   └── prod/prod.tfvars
│   ├── backends/               # Remote state backend configs
│   │   ├── dev.s3.backend.hcl
│   │   ├── staging.s3.backend.hcl
│   │   └── prod.s3.backend.hcl
│   └── modules/
│       ├── vpc/                # VPC with public/private/database subnets
│       ├── security-groups/    # ALB, EKS, RDS, Lambda, Bastion SGs
│       ├── ecr/                # Container registry with lifecycle
│       ├── s3/                 # S3 buckets with encryption
│       ├── kms/                # KMS keys for encryption
│       └── iam/                # IAM roles (EKS, Lambda, GitHub OIDC)
│
├── app-infrastructure/         # Application layer (depends on base)
│   ├── main.tf                 # Orchestrates app modules
│   ├── variables.tf            # Input variable definitions
│   ├── outputs.tf              # Application outputs
│   ├── providers.tf            # Provider configuration
│   ├── inputs/                 # Environment-specific configurations
│   ├── backends/               # Remote state backend configs
│   └── modules/
│       ├── eks/                # EKS cluster with node groups
│       ├── aurora/             # Aurora Serverless v2
│       ├── alb/                # Application Load Balancer
│       ├── lambda/             # Lambda functions
│       └── cognito/            # Cognito User Pools
│
├── scripts/
│   └── get_vars.sh             # Helper to load environment tfvars
│
├── .pre-commit-config.yaml     # Pre-commit hooks for quality
├── .tflint.hcl                 # TFLint configuration
└── .gitignore
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Multi-Environment** | Separate configurations for dev, staging, prod via `inputs/` |
| **Layered Architecture** | Base infrastructure deployed before application layer |
| **Remote State** | S3 backend with DynamoDB locking |
| **Pre-commit Hooks** | terraform_fmt, terraform_validate, tflint, checkov |
| **Modular Design** | Reusable modules with typed variables |
| **Security** | KMS encryption, security groups, VPC endpoints |

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- S3 bucket for state (`terraform-state-enterprise`)
- DynamoDB table for locking (`terraform-lock-table`)

### 1. Deploy Base Infrastructure

```bash
cd base-infrastructure

# Initialize with backend config
terraform init -backend-config=backends/dev.s3.backend.hcl

# Plan with environment variables
terraform plan $(../scripts/get_vars.sh dev base-infrastructure)

# Apply
terraform apply $(../scripts/get_vars.sh dev base-infrastructure)
```

### 2. Deploy Application Infrastructure

```bash
cd app-infrastructure

# Initialize
terraform init -backend-config=backends/dev.s3.backend.hcl

# Plan and apply
terraform plan $(../scripts/get_vars.sh dev app-infrastructure)
terraform apply $(../scripts/get_vars.sh dev app-infrastructure)
```

### Switching Environments

```bash
# Switch to staging
terraform init -backend-config=backends/staging.s3.backend.hcl -reconfigure
terraform plan $(../scripts/get_vars.sh staging base-infrastructure)

# Switch to production
terraform init -backend-config=backends/prod.s3.backend.hcl -reconfigure
terraform plan $(../scripts/get_vars.sh prod base-infrastructure)
```

## Module Documentation

### Base Infrastructure Modules

| Module | Resources | Description |
|--------|-----------|-------------|
| **vpc** | VPC, Subnets, NAT, IGW, VPC Endpoints, Flow Logs | Multi-AZ VPC with public/private/database tiers |
| **security-groups** | Security Groups | Pre-configured SGs for ALB, EKS, RDS, Lambda |
| **ecr** | ECR Repository, Lifecycle Policy | Container registry with image scanning |
| **s3** | S3 Bucket, Versioning, Encryption | Encrypted buckets with lifecycle rules |
| **kms** | KMS Key, Alias | Customer-managed encryption keys |
| **iam** | IAM Roles, Policies | EKS, Lambda, RDS, GitHub Actions OIDC roles |

### Application Infrastructure Modules

| Module | Resources | Description |
|--------|-----------|-------------|
| **eks** | EKS Cluster, Node Groups, OIDC | Managed Kubernetes with IRSA support |
| **aurora** | Aurora Cluster, Instances | Serverless v2 PostgreSQL/MySQL |
| **alb** | ALB, Target Groups, Listeners | Application Load Balancer with HTTPS |
| **lambda** | Lambda Function, CloudWatch Logs | Serverless functions with VPC support |
| **cognito** | User Pool, Clients | User authentication and authorization |

## Configuration Examples

### VPC Configuration

```hcl
vpc_config = {
  name         = "prod-vpc"
  primary_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # HA for production
  enable_flow_logs   = true

  vpc_endpoints = {
    s3     = { service = "s3", type = "Gateway" }
    ecr_api = { service = "ecr.api", type = "Interface" }
  }
}
```

### Aurora Serverless Configuration

```hcl
aurora_clusters = {
  main = {
    cluster_identifier = "main-db"
    engine             = "aurora-postgresql"
    engine_version     = "15.4"
    database_name      = "appdb"

    instance_class            = "db.serverless"
    serverlessv2_min_capacity = 0.5
    serverlessv2_max_capacity = 4

    backup_retention_period = 7
    deletion_protection     = true
    storage_encrypted       = true
  }
}
```

### EKS Configuration

```hcl
eks_config = {
  cluster_name    = "prod-cluster"
  cluster_version = "1.31"
  enable_irsa     = true

  node_groups = {
    general = {
      instance_types = ["m6i.large", "m6i.xlarge"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      capacity_type  = "ON_DEMAND"
    }
    spot = {
      instance_types = ["m6i.large", "m5.large"]
      min_size       = 0
      max_size       = 20
      desired_size   = 2
      capacity_type  = "SPOT"
    }
  }
}
```

## Pre-commit Hooks

Install and configure pre-commit:

```bash
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

Hooks included:
- `terraform_fmt` - Format HCL files
- `terraform_validate` - Validate configurations
- `terraform_tflint` - Lint with AWS rules
- `terraform_docs` - Generate documentation
- `terraform_checkov` - Security scanning

## Best Practices

1. **Always run plan before apply** - Review changes carefully
2. **Use workspaces sparingly** - Prefer separate state files per environment
3. **Lock provider versions** - Prevent unexpected upgrades
4. **Enable encryption everywhere** - KMS for sensitive data
5. **Use IRSA for EKS** - Avoid node-level permissions
6. **Tag all resources** - Environment, ManagedBy, CostCenter

## Troubleshooting

### State Lock Issues

```bash
# List locks
aws dynamodb scan --table-name terraform-lock-table

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Provider Authentication

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Refresh credentials if using SSO
aws sso login --profile your-profile
```

## Author

**Uwasan Maku** - Senior DevSecOps Engineer

[LinkedIn](https://www.linkedin.com/in/uwasan-maku) | [GitHub](https://github.com/Sir-seju)
