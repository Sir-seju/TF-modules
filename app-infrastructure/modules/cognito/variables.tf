variable "user_pool_name" {
  description = "User pool name"
  type        = string
}

variable "username_attributes" {
  description = "Username attributes"
  type        = list(string)
  default     = ["email"]
}

variable "auto_verified_attributes" {
  description = "Auto verified attributes"
  type        = list(string)
  default     = ["email"]
}

variable "mfa_configuration" {
  description = "MFA configuration"
  type        = string
  default     = "OPTIONAL"
}

variable "deletion_protection" {
  description = "Deletion protection"
  type        = string
  default     = "INACTIVE"
}

variable "password_policy" {
  description = "Password policy"
  type = object({
    minimum_length    = optional(number, 8)
    require_lowercase = optional(bool, true)
    require_uppercase = optional(bool, true)
    require_numbers   = optional(bool, true)
    require_symbols   = optional(bool, true)
  })
  default = {}
}

variable "schema_attributes" {
  description = "Schema attributes"
  type = list(object({
    name                = string
    attribute_data_type = string
    mutable             = optional(bool, true)
    required            = optional(bool, false)
    string_length_min   = optional(number, 0)
    string_length_max   = optional(number, 2048)
  }))
  default = []
}

variable "clients" {
  description = "User pool clients"
  type = list(object({
    name                = string
    generate_secret     = optional(bool, false)
    explicit_auth_flows = optional(list(string), ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
  }))
  default = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
