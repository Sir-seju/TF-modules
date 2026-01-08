variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  type        = string
}

variable "node_role_arn" {
  description = "EKS node IAM role ARN"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_public_access" {
  description = "Enable public endpoint"
  type        = bool
  default     = false
}

variable "enabled_cluster_log_types" {
  description = "Cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Node groups"
  type = map(object({
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
  }))
  default = {}
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
