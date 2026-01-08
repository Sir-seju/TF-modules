variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_eks_cluster_role" {
  description = "Create EKS cluster role"
  type        = bool
  default     = true
}

variable "create_eks_node_role" {
  description = "Create EKS node role"
  type        = bool
  default     = true
}

variable "create_lambda_execution_role" {
  description = "Create Lambda execution role"
  type        = bool
  default     = true
}

variable "create_rds_monitoring_role" {
  description = "Create RDS monitoring role"
  type        = bool
  default     = true
}

variable "create_github_actions_role" {
  description = "Create GitHub Actions OIDC role"
  type        = bool
  default     = false
}

variable "github_actions_oidc_provider" {
  description = "GitHub Actions OIDC provider ARN"
  type        = string
  default     = null
}

variable "github_actions_allowed_repos" {
  description = "GitHub repos allowed to assume role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
