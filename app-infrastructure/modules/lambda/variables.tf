variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 256
}

variable "role_arn" {
  description = "IAM role ARN"
  type        = string
}

variable "source_path" {
  description = "Source code path"
  type        = string
}

variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
