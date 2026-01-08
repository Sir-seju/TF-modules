bucket         = "terraform-state-enterprise"
key            = "base-infrastructure/staging/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock-table"
encrypt        = true
