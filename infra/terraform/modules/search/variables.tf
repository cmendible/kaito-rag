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

variable "sku" {
  description = "(Required) Specifies the SKU of the Azure AI Search. Possible values are `free`, `basic`, `standard`, `standard2`, `standard3`, `storage_optimized_l1` and `storage_optimized_l2`, Defaults to `free`."
  type        = string
  nullable    = false
  default     = "free"

  validation {
    condition     = can(regex("^(free|basic|standard|standard2|standard3|storage_optimized_l1|storage_optimized_l2)$", var.sku))
    error_message = "Invalid SKU. Possible values are `free`, `basic`, `standard`, `standard2`, `standard3`, `storage_optimized_l1` and `storage_optimized_l2`."
  }
}

variable "sku_semantic_search" {
  description = "(Optional) Specifies the Semantic Search SKU which should be used for this Azure AI Search Service. Possible values are `free`, `standard` and `null` if no Semantic Search should be used. To use this feature, the Azure AI Search SKI cannot be `free`. Defaults to `null`."
  type        = string
  default     = null

  validation {
    condition     = var.sku != "free" || var.sku_semantic_search == null
    error_message = "Semantic Search SKU cannot be 'free' or 'standard' when the Azure AI Search SKU is 'free'."
  }

  validation {
    condition     = var.sku_semantic_search == null || can(regex("^(free|standard)$", var.sku_semantic_search))
    error_message = "Invalid Semantic Search SKU. Possible values are `free`, `standard` or `null` if no Semantic Search should be used."
  }
}

# # variable "index_name_document_grounding" {
# #   description = "(Optional) Specifies the name of the index for document grounding. Defaults to `document-grounding`."
# #   type        = string
# #   nullable    = false
# #   default     = "document-grounding"
# # }

