variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure Manage Identity."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Manage Identity."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Manage Identity."
  default     = {}
  nullable    = false
}
