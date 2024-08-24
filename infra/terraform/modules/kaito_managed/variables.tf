variable "resource_group_id" {
  description = "(Required) Specifies the resource id of the resource group."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

/* Kaito */

variable "aks_id" {
  description = "(Required) The ID of the AKS cluster."
  type        = string
  nullable    = false
}

variable "aks_node_resource_group_name" {
  description = "(Required) The name of the resource group of the AKS cluster node."
  type        = string
  nullable    = false
}

variable "aks_oidc_issuer_url" {
  description = "(Required) The OIDC issuer URL of the AKS cluster."
  type        = string
  nullable    = false
}

variable "ask_workload_managed_identity_client_id" {
  description = "(Required) Specifies the client ID of the Azure OpenAI Service Workload Managed Identity."
  type        = string
  nullable    = false
}

variable "ask_workload_managed_identity_id" {
  description = "(Required) Specifies the client ID of the Azure OpenAI Service Workload Managed Identity."
  type        = string
  nullable    = false
}

variable "kaito_instance_type_vm_size" {
  description = "(Optional) Specifies the GPU node SKU. This field defaults to `Standard_NC6s_v3` if not specified."
  type        = string
  default     = "Standard_NC6s_v3"
}

variable "kaito_identity_name" {
  description = "(Required) Specifies the object ID of the User Assigned Identity to associate with Kaito."
  type        = string
  nullable    = false
}

variable "kaito_identity_resource_group_name" {
  description = "(Required) Specifies the object ID of the User Assigned Identity to associate with Kaito."
  type        = string
  nullable    = false
}

variable "kaito_aks_namespace" {
  description = "(Optional) Specifies the namespace of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag`."
  type        = string
  nullable    = false
  default     = "kaito-rag"
}

variable "kaito_service_account_name" {
  description = "(Optional) Specifies the name of the service account of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag-sa`."
  type        = string
  nullable    = false
  default     = "kaito-rag-sa"
}

variable "tenant_id" {
  description = "(Required) The Tenant ID of the System Assigned Identity which is used by master components."
  type        = string
  nullable    = false
}

variable "dns_zone_name" {
  description = "(Required) The name of the DNS zone."
  type        = string
  nullable    = false
}

variable "kaito_ai_model" {
  description = "(Required) Specifies the name of the AI model to deploy with Kaito. Not all models are supported. Please refer to the Kaito documentation for more information here: https://github.com/Azure/kaito/blob/main/presets/README.md"
  type        = string
  nullable    = false
}
