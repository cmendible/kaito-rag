variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure NAT Gateway."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure NAT Gateway."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "(Optional) The SKU which should be used. At this time the only supported value is `Standard`. Defaults to `Standard`."
  type        = string
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard"
    error_message = "The NAT Gateway SKU is incorrect. Possible values are `Standard`."
  }
}

variable "zones" {
  description = " (Optional) A list of Availability Zones in which this NAT Gateway should be located. Changing this forces a new NAT Gateway to be created."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "subnet_ids" {
  description = "(Required) A map of subnet IDs to associate with the NAT Gateway."
  type        = map(string)
  nullable = false
}

variable "idle_timeout_in_minutes" {
  description = "(Optional) The idle timeout which should be used in minutes. Defaults to 4."
  type        = number
  nullable    = false
  default     = 4
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure NAT Gateway."
  type        = map(any)
  nullable    = false
  default     = {}
}
