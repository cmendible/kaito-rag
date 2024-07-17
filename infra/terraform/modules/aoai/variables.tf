variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure Virtual Network."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Virtual Network."
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
