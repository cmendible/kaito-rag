variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure Log Analytics Workspace."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Log Analytics Workspace."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "(Optional) Specifies the sku of the Azure Log Analytics Workspace."
  type        = string
  nullable    = false
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "Standalone", "PerNode", "PerGB2018"], var.sku)
    error_message = "The log analytics sku is incorrect. Possible values are `Free`, `Standalone`, `PerNode`, `PerGB2018`."
  }
}

variable "retention_in_days" {
  description = " (Optional) Specifies the workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730. Default is 30."
  type        = number
  nullable    = true
  default     = 30

  validation {
    condition     = var.retention_in_days == 7 || (var.retention_in_days >= 30 && var.retention_in_days <= 730)
    error_message = "The retention in days should be either 7 (Free Tier only) or range between 30 and 730."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  nullable    = false
  default     = {}
}
