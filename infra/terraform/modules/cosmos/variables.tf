variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Cosmos DB."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Cosmos DB."
  type        = string
  nullable    = false
}

variable "database_name" {
  description = "(Required) Specifies the name of the database in CosmosDB."
  type        = string
  nullable    = false
}

variable "container_name_chat_history" {
  description = "(Required) Specifies the name of the container in CosmosDB that will store the chat history indexed by `userId`."
  type        = string
  nullable    = false
}

variable "throughput" {
  description = "(Required) Cosmos DB database throughput. This value should be equal to or greater than 400 and less than or equal to 1000000, in increments of 100. Default is 400."
  type        = number
  nullable    = false
  default     = 400

  validation {
    condition     = var.throughput >= 400 && var.throughput <= 1000000
    error_message = "Cosmos DB manual throughput should be equal to or greater than 400 and less than or equal to 1000000."
  }

  validation {
    condition     = var.throughput % 100 == 0
    error_message = "Cosmos DB throughput should be in increments of 100."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of this Cosmos DB resource."
  default     = {}
  nullable    = false
}
