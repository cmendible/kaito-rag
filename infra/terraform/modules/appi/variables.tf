variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure Application Insights."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Application Insights."
  type        = string
  nullable    = false
}

variable "log_analytics_workspace_id" {
  description = "(Required) Specifies the resource ID of the Azure Log Analytics Workspace."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  default     = {}
}
