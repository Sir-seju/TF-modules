# ==============================================================================
# VPC Module Variables
# ==============================================================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "primary_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string
}

variable "secondary_cidrs" {
  description = "List of secondary CIDR blocks for the VPC"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost optimization)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention for flow logs"
  type        = number
  default     = 30
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create"
  type = map(object({
    service             = string
    type                = string
    private_dns_enabled = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
