variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the Azure Container Registry (ACR). Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Container Registry (ACR). Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "admin_enabled" {
  description = "(Optional) Specifies whether the admin user is enabled. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "sku" {
  description = "(Optional) The SKU name of the Azure Container Registry (ACR). Possible values are `Basic`, `Standard` and `Premium`. Defaults to `Basic`"
  type        = string
  nullable    = false
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The Azure Container Registry (ACR) SKU is invalid. Possible values are `Basic`, `Standard` and `Premium`."
  }
}

variable "georeplication_locations" {
  description = "(Optional) A list of Azure locations where the Azure Container Registry (ACR) should be geo-replicated."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Specifies the resource id of the Azure Log Analytics workspace."
  type        = string
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(any)
  default     = {}
}
