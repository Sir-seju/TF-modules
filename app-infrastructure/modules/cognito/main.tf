# ==============================================================================
# Cognito User Pool Module
# ==============================================================================

resource "aws_cognito_user_pool" "this" {
  name                     = var.user_pool_name
  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes
  mfa_configuration        = var.mfa_configuration
  deletion_protection      = var.deletion_protection

  password_policy {
    minimum_length    = var.password_policy.minimum_length
    require_lowercase = var.password_policy.require_lowercase
    require_uppercase = var.password_policy.require_uppercase
    require_numbers   = var.password_policy.require_numbers
    require_symbols   = var.password_policy.require_symbols
  }

  dynamic "schema" {
    for_each = var.schema_attributes
    content {
      name                = schema.value.name
      attribute_data_type = schema.value.attribute_data_type
      mutable             = schema.value.mutable
      required            = schema.value.required

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [1] : []
        content {
          min_length = schema.value.string_length_min
          max_length = schema.value.string_length_max
        }
      }
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = { for idx, client in var.clients : client.name => client }

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret     = each.value.generate_secret
  explicit_auth_flows = each.value.explicit_auth_flows

  prevent_user_existence_errors = "ENABLED"
}
