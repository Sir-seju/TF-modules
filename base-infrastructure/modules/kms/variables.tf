variable "alias_name" {
  description = "KMS key alias name"
  type        = string
}

variable "description" {
  description = "KMS key description"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Deletion window in days"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable key rotation"
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "Key usage"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "policy" {
  description = "KMS key policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
