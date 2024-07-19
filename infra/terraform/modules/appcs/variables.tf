variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure App Configuration."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure App Configuration."
  type        = string
  nullable    = false
}

variable "principal_id" {
  description = "(Required) Specifies the principal ID of the user assigned identity."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  default     = {}
}

variable "sku" {
  description = "(Required) Specifies the SKU of the Azure App Configuration. Possible values are `free` and `standard`. Defaults to `free`."
  type        = string
  nullable    = false
  default     = "free"

  validation {
    condition     = contains(["free", "standard"], var.sku)
    error_message = "The Azure App Configuration SKU is incorrect. Possible values are `free` and `standard`."
  }
}

variable "key_vault_id" {
  description = "(Required) Specifies the resource id of the Azure Key Vault where to store secrets created by the Azure Bot."
  type        = string
  nullable    = false
}

variable "local_authentication_enabled" {
  description = "(Optional) Specifies whether or not local authentication should be enabled for this Azure App Configuration resource. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This field only works for standard sku. This value can be between 1 and 7 days. Defaults to 7. Changing this forces a new resource to be created."
  type        = number
  nullable    = false
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 7
    error_message = "The soft delete retention days must be between 1 and 7 days and only works for the standard SKU."
  }
}

variable "public_network_access" {
  description = "(Optional) The Public Network Access setting of the App Configuration. Possible values are `Enabled` and `Disabled`. Defaults to `Enabled`."
  type        = string
  nullable    = false
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "The Public Network Access setting of the App Configuration is incorrect. Possible values are `Enabled` and `Disabled`."
  }
}

variable "identity_type" {
  description = " (Required) Specifies the type of Managed Service Identity that should be configured on this App Configuration. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). Defaults to both enalbe."
  type        = string
  nullable    = false
  default     = "SystemAssigned, UserAssigned" # Default both enalbe

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "The Managed Service Identity type is incorrect. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned`."
  }
}

variable "identity_ids" {
  description = "(Optional) Specifies the list of user assigned identities to be associated with the App Configuration."
  type        = list(string)
  nullable    = false
  default     = []
}
