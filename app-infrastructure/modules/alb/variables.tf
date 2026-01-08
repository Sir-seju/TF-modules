variable "name" {
  description = "ALB name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "internal" {
  description = "Internal ALB"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "Access logs S3 bucket"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = null
}

variable "target_groups" {
  description = "Target groups"
  type = map(object({
    port              = number
    protocol          = optional(string, "HTTP")
    target_type       = optional(string, "ip")
    health_check_path = optional(string, "/health")
  }))
  default = {}
}

variable "listener_rules" {
  description = "Listener rules"
  type = list(object({
    priority         = number
    host_header      = optional(list(string))
    path_pattern     = optional(list(string))
    target_group_key = string
  }))
  default = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
