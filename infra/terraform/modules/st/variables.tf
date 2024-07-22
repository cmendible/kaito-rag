variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure Storage Account."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure Storage Account."
  type        = string
  nullable    = false
}

variable "account_tier" {
  description = "(Required) Defines the Tier to use for this Azure Storage Account. Valid options are `Standard` and `Premium`. Changing this forces a new resource to be created. Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = can(regex("^(Standard|Premium)$", var.account_tier))
    error_message = "Invalid account_tier. Valid options are `Standard` and `Premium`."
  }
}

variable "account_replication_type" {
  description = "(Required) Defines the type of replication to use for this Azure Storage Account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. Changing this forces a new resource to be created when types `LRS`, `GRS` and `RAGRS` are changed to `ZRS`, `GZRS` or `RAGZRS` and vice versa. Defaults to `LRS`."
  type        = string
  nullable    = false
  default     = "LRS"

  validation {
    condition     = can(regex("^(LRS|GRS|RAGRS|ZRS|GZRS|RAGZRS)$", var.account_replication_type))
    error_message = "Invalid account_replication_type. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Storage Account."
  type        = map(any)
  nullable    = false
  default     = {}
}
