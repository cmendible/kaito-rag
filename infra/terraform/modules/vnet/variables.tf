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

variable "address_space" {
  description = "(Required) The address space that is used the Azure Virtual Network."
  type        = list(string)
  nullable    = false
}

variable "subnets" {
  description = "(Optional) The subnets and their configuration that are used in the AzureVirtual Network."
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    private_endpoint_network_policies             = string
    private_link_service_network_policies_enabled = bool
    delegation                                    = string
  }))
  nullable = true

  validation {
    condition     = alltrue([
      for subnet in var.subnets : 
        subnet == null 
          ? true 
          : contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], subnet.private_endpoint_network_policies)
    ])
    error_message = "The `private_endpoint_network_policies` must be either `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled`, or `RouteTableEnabled`."
  }
}

variable "log_analytics_workspace_id" {
  description = "(Required) Specifies the resource id of the Azure Log Analytics Workspace."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Virtual Network resource."
  default     = {}
  nullable    = false
}
