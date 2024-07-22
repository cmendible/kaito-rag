variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "resource_group_id" {
  description = "(Required) Specifies the resource id of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location where the SSH Keys will be deployed."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the SSH Key resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags of the SSH Public Key resource."
  default     = {}
  nullable    = false
}
