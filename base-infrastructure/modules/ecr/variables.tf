variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "Lifecycle policy configuration"
  type = object({
    max_image_count      = number
    expire_untagged_days = number
  })
  default = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
