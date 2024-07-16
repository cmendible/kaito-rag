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
    error_message = "The log analytics sku is incorrect."
  }
}

# variable "solution_plan_map" {
#   description = "(Optional) Specifies the map structure containing the list of solutions to be enabled into the Log Analytics Workspace."
#   type        = map(any)
#   default     = {}
# }

variable "retention_in_days" {
  description = " (Optional) Specifies the workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730."
  type        = number
  nullable    = true
  default     = 30
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  nullable    = false
  default     = {}
}
