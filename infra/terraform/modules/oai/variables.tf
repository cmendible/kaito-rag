variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "(Required) Specifies the location of the Azure OpenAI."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the Azure OpenAI."
  type        = string
  nullable    = false
}

variable "identity_ids" {
  description = "(Optional) Specifies the list of user assigned identities to be associated with this resource."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "tags" {
  description = "(Optional) Specifies the tags for this resource."
  type        = map(any)
  default     = {}
}
