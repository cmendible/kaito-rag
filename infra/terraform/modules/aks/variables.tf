variable "location" {
  description = "(Required) Specifies the location where this Azure Kubernetes Service (AKS) cluster will be deployed."
  type        = string
  nullable    = false
}

variable "name" {
  description = "(Required) Specifies the name of the SSH Key resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "aks-kaito-rag"
}

variable "resource_group_id" {
  description = "(Required) Specifies the resource ID of the resource group."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "(Required) The Tenant ID of the Microsoft Entra ID (former Azure Active Directory or Azure AD) which should be used for Role Based Access Control (RBAC) in this Azure Kubernetes Service (AKS) Cluster."
  type        = string
  nullable    = false
}

variable "admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Microsoft Entra ID (former Azure Active Directory) which should have Admin Role on this Azure Kubernetes Service (AKS) Cluster."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "sku" {
  description = "(Optional) The SKU Tier that should be used for this Azure Kubernetes Service (AKS) Cluster. Possible values are `Free`, `Standard`, `Premium` (which includes the Uptime SLA). Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku)
    error_message = "The SKU tier is invalid. Possible values are `Free`, `Standard`. `Premium`."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Kubernetes Services (AKS) resource."
  default     = {}
  nullable    = false
}

variable "use_node_resource_group" {
  description = "(Optional) Specifies wheter the AKS nodes be located on a specific resource group or not. The resource group name will be the same as the `resource_group_name` variable plus `-nodes`. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "kubernetes_version" {
  description = "(Required) Specifies the AKS Kubernetes version. Defaults to `1.30`."
  type        = string
  nullable    = false
  default     = "1.30"
}

variable "admin_username" {
  description = "(Required) Specifies the Admin Username for the Azure Kubernetes Service (AKS) cluster worker nodes. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "(Required) Specifies the SSH public key used to access the cluster. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "dns_prefix" {
  description = "(Optional) DNS prefix specified when creating the managed cluster. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "msi_name" {
  description = "(Required) Specifies the name of an Azure User Assigned Identity to use with this Azure Kubernetes Service (AKS) Cluster."
  type        = string
  nullable    = false
}

variable "msi_resource_group_name" {
  description = "(Optional) Specifies the name of the resource group where the Azure User Assigned Identity for this Azure Kubernetes Service (AKS) is located. If the value is `null`the resource group name of the AKS will be used."
  nullable    = true
  default     = null
}

/* Operations Management Suite (OMS) Agent Add-on */

variable "log_analytics_workspace_id" {
  description = "(Optional) The ID of the Log Analytics Workspace which the Operation Management Suite Agent (OMS Agent) should send data to. Must be present if `msi_auth_for_monitoring_enabled` is `true`."
  type        = string
  default     = null

  validation {
    condition     = var.msi_auth_for_monitoring_enabled == true ? length(var.log_analytics_workspace_id) > 0 : true
    error_message = "The Log Analytics Workspace ID must be present if MSI authentication for monitoring (`msi_auth_for_monitoring_enabled`) is enabled."
  }
}

variable "msi_auth_for_monitoring_enabled" {
  description = "(Optional) Specifies whether to use Managed Service Identity (MSI) authentication for the Operation Management Suite Agent (OMS Agent). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

/* SYSTEM NODE POOL */

variable "system_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within the System Node Pool. Valid values are between 0 and 1000. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
}

variable "system_node_pool_vm_size" {
  description = "(Required) Specifies the Virtual Machine size (SKU) which should be used for the Virtual Machines used for the System Node Pool. Changing this forces a new resource to be created. Defaults to `Standard_D2s_v5`."
  type        = string
  nullable    = false
  default     = "Standard_D2s_v5"
}

variable "system_node_pool_vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the Kubernetes System Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "user_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "user_node_pool_name" {
  description = "(Required) Specifies the name of the User Node Pool. Default is `user`."
  type        = string
  nullable    = false
  default     = "user"
}

variable "user_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be a value in the range `user_node_pool_min_count - user_node_pool_max_count`. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
}

variable "user_node_pool_node_labels" {
  description = "(Optional) A map of Kubernetes taints which should be applied to nodes in this User Node Pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "user_node_pool_node_taints" {
  description = "(Optional) A list of Kubernetes taints which should be applied to nodes in the User Node Pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "user_node_pool_vm_size" {
  description = "(Required) Specifies the Virtual Machine size (SKU) which should be used for the Virtual Machines used for the User Node Pool. Changing this forces a new resource to be created. Defaults to `Standard_D4ds_v4`."
  type        = string
  nullable    = false
  default     = "Standard_D4ds_v4"
}

variable "user_node_pool_vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the User Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}
