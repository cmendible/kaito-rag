variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Key Vault."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Key Vault."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "(Required) The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault."
  type        = string
  nullable    = false
}

variable "principal_id" {
  description = "(Required) The object ID of the principal to grant access to the Key Vault."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "(Required) The SKU name of the Key Vault. Possible values are `Standard` and `Premium`. Default is `Standard`."
  type        = string
  nullable    = true
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard" || var.sku == "Premium"
    error_message = "The SKU name of the Key Vault must be either `Standard` or `Premium`."
  }
}

variable "soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. Default is 7 days."
  type        = number
  nullable    = true
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "The number of days that items should be retained for once soft-deleted should be between 7 and 90 days."
  }
}

variable "secrets" {
  description = "(Optional) Specifies the secrets to be created in the Key Vault."
  type = list(object({
    name  = string
    value = string
  }))
  nullable = true
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Key Vault resource."
  default     = {}
  nullable    = false
}
