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

variable "tenant_id" {
  description = "(Required) The Tenant ID of the System Assigned Identity which is used by master components."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "(Optional) Specifies the tags to associate with related Kaito resources."
  default     = {}
  nullable    = false
}

/* AKS Parameters */

variable "aks_id" {
  description = "(Required) The ID of the AKS cluster."
  type        = string
  nullable    = false
}

variable "aks_name" {
  description = "(Required) The name of the AKS cluster."
  type        = string
  nullable    = false
}

variable "aks_location" {
  description = "(Required) The name of the AKS cluster."
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

/* GPU Provisioner */

variable "gpu_provisioner_version" {
  description = "(Required) Specifies the version of the GPU provisioner. Currently, the only supported versions are `0.1.0` and `0.2.0`. Defaults to `0.2.0`. More info: https://github.com/Azure/gpu-provisioner/blob/main/charts/gpu-provisioner/README.md"
  type        = string
  nullable    = false
  default     = "0.2.0"

  validation {
    condition     = can(regex("0.1.0|0.2.0", var.gpu_provisioner_version))
    error_message = "Currently, the GPU provisioner version must be either `0.1.0` or `0.2.0`."
  }
}

variable "gpu_provisioner_replicas" {
  description = "(Optional) Specifies the number of replicas of the GPU provisioner. Defaults to `1`."
  type        = number
  nullable    = false
  default     = 1
}

/* NSG Paramters */

variable "network_security_group_name" {
  description = "(Required) Specifies the name of the Azure Network Security Group (NSG) to configure with rules for the Ollama service."
  type        = string
  nullable    = false
}

/* Kaito */

variable "use_upstream_version" {
  description = "(Optional) If `true`, the upstream version of Kaito from GitHub will be used. If `false`, the Azure managed Kaito version is used. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "kaito_inference_port" {
  description = "(Required) Specifies the port on which the Kaito inference service listens. Defaults to `5000`."
  type        = number
  nullable    = false
  default     = 5000
}

variable "kaito_instance_type_vm_size" {
  description = "(Optional) Specifies the GPU node SKU. This field defaults to `Standard_NC6s_v3` if not specified."
  type        = string
  default     = "Standard_NC6s_v3"
}

variable "kaito_aks_namespace" {
  description = "(Optional) Specifies the namespace of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag`."
  type        = string
  nullable    = false
  default     = "kaito-rag"
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

variable "kaito_service_account_name" {
  description = "(Optional) Specifies the name of the service account of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag-sa`."
  type        = string
  nullable    = false
  default     = "kaito-rag-sa"
}

variable "kaito_ai_model" {
  description = "(Required) Specifies the name of the AI model to deploy with Kaito. Not all models are supported. Please refer to the Kaito documentation for more information here: https://github.com/Azure/kaito/blob/main/presets/README.md"
  type        = string
  nullable    = false
}
