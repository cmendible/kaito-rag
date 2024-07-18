variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Bot."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Optional) Specifies the location of the Azure Bot. Currently an Azure Bot can only be deployed in the following locations: `global`, `westeurope` or `centralindia`. Defaults to `global`."
  type        = string
  nullable    = false
  default     = "global"

  validation {
    condition     = contains(["global", "westeurope", "centralindia"], var.location)
    error_message = "The Azure Bot location is incorrect. Possible values are `global`, `westeurope` or `centralindia`."
  }
}

variable "user_assigned_identity_location" {
  description = "(Optional) Specifies the location of the Azure Bot User Assigned Identity. This value is ignored when `bot_type` is `SingleTenant` or `MultiTenant`."
  type        = string
  default     = null
}

variable "type" {
  description = "(Optional) Specifies the type of the Azure Bot. Possible values are `SingleTenant`, `MultiTenant` or `functions`. Defaults to `SingleTenant`."
  type        = string
  nullable    = false
  default     = "SingleTenant"

  validation {
    condition     = contains(["SingleTenant", "MultiTenant", "UserAssignedMSI"], var.type)
    error_message = "The Azure Bot type is incorrect. Possible values are `SingleTenant`, `MultiTenant` or `functions`."
  }
}

variable "backend_endpoint" {
  description = "(Required) Specifies the backend endpoint of the Azure Bot. This value is also known as the messaging endpoint."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "(Optional) Specifies the sku of the Azure Bot. Defaults to `F0`."
  type        = string
  nullable    = false
  default     = "F0"

  validation {
    condition     = contains(["F0", "S1"], var.sku)
    error_message = "The Azure Bot sku is incorrect. Possible values are `F0` or `S1`."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "application_insights_id" {
  description = "(Required) Specifies the resource id of the Azure Application Insights."
  type        = string
  nullable    = false
}

variable "application_insights_instrumentation_key" {
  description = "(Required) Specifies the instrumentation key of the Azure Application Insights."
  type        = string
  nullable    = false
}

variable "application_insights_app_id" {
  description = "(Required) Specifies the app id of the Azure Application Insights."
  type        = string
  nullable    = false
}

variable "key_vault_id" {
  description = "(Required) Specifies the resource id of the Azure Key Vault where to store secrets created by the Azure Bot."
  type        = string
  nullable    = false
}
