
variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location where the Azure Public IP will be deployed."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Public IP resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Public IP resource."
  default     = {}
  nullable    = false
}
