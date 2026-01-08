variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block public access"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules"
  type = list(object({
    id                         = string
    enabled                    = bool
    prefix                     = optional(string, "")
    expiration_days            = optional(number)
    noncurrent_expiration_days = optional(number)
    transition = optional(list(object({
      days          = number
      storage_class = string
    })))
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS rules"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    max_age_seconds = optional(number, 3000)
  }))
  default = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
