variable "resource_group_name" {
  description = "(Required) The name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location for the Azure Virtual Network resources."
  type        = string
  nullable    = false
}

variable "log_analytics_workspace_id" {
  description = "(Required) Specifies the resource ID of the Azure Log Analytics Workspace to monitor this Azure Virtual Network resource."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Virtual Network resource."
  default     = {}
  nullable    = false
}

/* VIRTUAL NETWORK */

variable "vnet_name" {
  description = "(Required) Specifies the name of the Azure Virtual Network."
  type        = string
  nullable    = false
}

variable "vnet_address_space" {
  description = "(Required) The address space that is used the Azure Virtual Network."
  type        = list(string)
  nullable    = false
}

/* SUBNET */

variable "subnet_name" {
  description = "(Required) Specifies the name of the Azure Subnet."
  type        = string
  nullable    = false
}

variable "subnet_address_space" {
  description = "(Required) The address space that is used the Azure Subnet."
  type        = list(string)
  nullable    = false
}

/* NETWORK SECURITY GROUP */

variable "nsg_name" {
  description = "(Required) Specifies the name of the Azure Network Security Group (NSG)."
  type        = string
  nullable    = false
}
