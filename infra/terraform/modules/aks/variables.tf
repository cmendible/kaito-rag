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

variable "sku" {
  description = "(Optional) The SKU Tier that should be used for this Azure Kubernetes Service (AKS) Cluster. Possible values are `Free` and `Paid` (which includes the Uptime SLA). Defaults to `Free`."
  type        = string
  nullable    = false
  default     = "Free"

  validation {
    condition     = contains(["Free", "Paid"], var.sku)
    error_message = "The SKU tier is invalid. Possible values are `Free` and `Paid`."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the Azure Kubernetes Services (AKS) resource."
  default     = {}
  nullable    = false
}

/* AKS */

variable "admin_username" {
  description = "(Required) Specifies the Admin Username for the Azure Kubernetes Service (AKS) cluster worker nodes. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "azureadmin"
}

variable "automatic_channel_upgrade" {
  description = "(Optional) The upgrade channel for this Azure Kubernetes Service (AKS) Cluster. Possible values are `patch`, `rapid`, and `stable`. Defaults to `stable`."
  type        = string
  nullable    = false
  default     = "stable"

  validation {
    condition     = contains(["patch", "rapid", "stable"], var.automatic_channel_upgrade)
    error_message = "The upgrade mode is invalid. Possible values are `patch`, `rapid`, and `stable`."
  }
}

variable "azure_policy_enabled" {
  description = "(Optional) Should the Azure Policy Add-On be enabled? For more details please visit Understand Azure Policy for Azure Kubernetes Service (AKS). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "http_application_routing_enabled" {
  description = "(Optional) Should HTTP Application Routing be enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "image_cleaner_enabled" {
  description = "(Optional) Specifies whether Image Cleaner is enabled. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "(Optional) Specifies the interval in hours when images should be cleaned up. Defaults to 48 (hours)."
  type        = number
  nullable    = false
  default     = 48
}

variable "kubernetes_version" {
  description = "(Optional) Specifies the AKS Kubernetes version. Defaults to `1.29.5`."
  type        = string
  nullable    = false
  default     = "1.29.5"
}

variable "oidc_issuer_enabled" {
  description = "(Optional) Enable or Disable the OpenID Connect (OIDC) issuer URL. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "open_service_mesh_enabled" {
  description = "(Optional) Is Open Service Mesh enabled? For more details, please visit Open Service Mesh for Azure Kubernetes Service (AKS). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "private_cluster_enabled" {
  description = "(Optional) Should this Kubernetes Cluster have its API server only exposed on internal IP addresses? This provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "ssh_public_key" {
  description = "(Required) Specifies the SSH public key used to access the cluster. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "workload_identity_enabled" {
  description = "(Optional) Specifies whether Microsoft Entra (former Azure Active Directory or Azure AD) Workload Identity should be enabled for the Cluster. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

/* Role-Based Access Control - RBAC */

variable "admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "azure_rbac_enabled" {
  description = "(Optional) Is Role Based Access Control based on Microsoft Entra (former Azure Active Directory or Azure AD) enabled? Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_aks_rbac_cluster_admin_assignment" {
  description = "(Optional) Indicates wheter the Azure Kubernetes Service (AKS) ACluster Admin role should be assigned to the list of principal IDs defined in `admin_group_object_ids`. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "tenant_id" {
  description = "(Required) The Tenant ID of the System Assigned Identity which is used by main components."
  type        = string
  nullable    = false
}

/* Network */

variable "dns_prefix" {
  description = "(Optional) DNS prefix specified when creating the managed cluster. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "dns_service_ip" {
  description = "(Optional) Specifies the DNS service IP."
  type        = string
  nullable    = false
  default     = "172.16.0.10"
}

variable "network_mode" {
  description = "(Optional) Network mode to be used with Azure CNI (Container Network Interface). Possible values are `bridge` and `transparent`. Changing this forces a new resource to be created. Defaults to `transparent`."
  nullable    = false
  type        = string
  default     = "transparent"

  validation {
    condition     = contains(["bridge", "transparent"], var.network_mode)
    error_message = "The network mode is invalid. Possible values are `bridge` and `transparent`."
  }
}

variable "network_plugin" {
  description = "(Optional) Specifies the network plugin of the Azure Kubernetes Service (AKS) cluster. Possible values are `azure`, `kubenet` or `none`. Defaults to `azure`."
  type        = string
  nullable    = false
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "The network plugin is invalid. Possible values are `azure`, `kubenet` or `none`."
  }
}

variable "network_plugin_mode" {
  description = "(Optional) Specifies the network plugin mode used for building the Kubernetes network. Possible values are `overlay` or `null`. Defauls is `overlay`."
  type        = string
  nullable    = true
  default     = "overlay"

  validation {
    condition     = var.network_plugin_mode == null ? true : contains(["overlay"], var.network_plugin_mode)
    error_message = "The network plugin mode value is incorrect. Possible values are `overlay` or `null`."
  }
}

variable "network_policy" {
  description = " (Optional) Sets up network policy to be used with Azure CNI (Container Network Interface). Network policy allows us to control the traffic flow between pods. Currently supported values are `calico`, `azure` and `cilium`. Defaults to `azure`."
  type        = string
  nullable    = false
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "The network policy is invalid. Possible values are `azure`, `calico` and `cilium`."
  }
}

variable "outbound_type" {
  description = "(Optional) The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are `loadBalancer`, `userDefinedRouting`, `userAssignedNATGateway` or `managedNATGateway`. Defaults to `loadBalancer`."
  type        = string
  nullable    = false
  default     = "userDefinedRouting"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "userAssignedNATGateway", "managedNATGateway"], var.outbound_type)
    error_message = "The outbound type is invalid. Possible values are `loadBalancer`, `userDefinedRouting`, `userAssignedNATGateway` or `managedNATGateway`."
  }
}

variable "pod_cidr" {
  description = "(Optional) Specifies the Classless Inter-Domain Routing (CIDR) to use for pod IP addresses. This field can only be set when `network_plugin` is set to `kubenet` or `network_plugin_mode` is set to `overlay`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "172.0.0.0/16"
}

variable "service_cidr" {
  description = "(Optional) Specifies the service Classless Inter-Domain Routing (CIDR) or Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "172.16.0.0/16"
}

/* Monitoring Metrics */

variable "annotations_allowed" {
  description = "(Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric."
  type        = string
  default     = null
}

variable "labels_allowed" {
  description = "(Optional) Specifies a comma-separated list of additional Kubernetes label keys that will be used in the resource's labels metric."
  type        = string
  default     = null
}

/* Workload auto-scaling */

variable "keda_enabled" {
  description = "(Optional) Specifies whether Kubernetes Event-driven Autoscaling (KEDA) Autoscaler  can be used for workloads. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "vertical_pod_autoscaler_enabled" {
  description = "(Optional) Specifies whether Vertical Pod Autoscaler should be enabled. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

/* Operations Management Suite (OMS) Agent Add-on */

variable "log_analytics_workspace_id" {
  description = "(Optional) The ID of the Log Analytics Workspace which the Operation Management Suite Agent (OMS Agent) should send data to. Must be present if enabled is `true`."
  type        = string
  default     = null
}

variable "msi_auth_for_monitoring_enabled" {
  description = "(Optional) Specifies whether to use Managed Service Identity (MSI) authentication for the Operation Management Suite Agent (OMS Agent). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

/* Application HTTP Routing Add-on */

variable "web_app_routing" {
  description = "Specifies the Application HTTP Routing add-on configuration."
  nullable    = false
  type = object({
    enabled     = bool
    dns_zone_id = string
  })
  default = {
    enabled     = false
    dns_zone_id = null
  }
}

/* Ingress Application Gateway Add-on */

variable "ingress_application_gateway" {
  description = "Specifies the Application Gateway Ingress Controller add-on configuration."
  nullable    = false
  type = object({
    enabled      = bool
    gateway_id   = string
    gateway_name = string
    subnet_cidr  = string
    subnet_id    = string
  })
  default = {
    enabled      = false
    gateway_id   = null
    gateway_name = null
    subnet_cidr  = null
    subnet_id    = null
  }
}

/* SYSTEM NODE POOL */

variable "system_node_pool_availability_zones" {
  description = "(Optional) A list of Availability Zones where the Nodes in this System Node Pool should be created in. Changing this forces a new resource to be created."
  type        = list(string)
  nullable    = false
  default     = ["1", "2", "3"]
}

variable "system_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = true
}

variable "system_node_pool_enable_host_encryption" {
  description = "(Optional) Should the nodes in this System Node Pool have host encryption enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "system_node_pool_enable_node_public_ip" {
  description = "(Optional) Should each node have a Public IP Address? Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "system_node_pool_max_count" {
  description = "(Required) The maximum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to `min_count`. Defaults to 10."
  type        = number
  nullable    = false
  default     = 30
}

variable "system_node_pool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created. Defaults to 10."
  type        = number
  nullable    = false
  default     = 30
}

variable "system_node_pool_min_count" {
  description = "(Required) The minimum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be less than or equal to `max_count`. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
}

variable "system_node_pool_name" {
  description = "(Optional) Specifies the name of the System Node Pool. Default is `system`."
  type        = string
  nullable    = false
  default     = "system"
}

variable "system_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be a value in the range `min_count - max_count`. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
}

variable "system_node_pool_node_labels" {
  description = "(Optional) A map of Kubernetes taints which should be applied to nodes in the System Node Pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "system_node_pool_only_critical_addons_enabled" {
  description = "(Optional) Enabling this option will taint default node pool with `CriticalAddonsOnly=true:NoSchedule` taint. The `temporary_name_for_rotation` value must be specified when changing this property. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "system_node_pool_os_disk_type" {
  description = "(Optional) The type of disk which should be used for the Operating System (OS) for the System Node Pool. Possible values are `Ephemeral` and `Managed`. Defaults to `Ephemeral`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Ephemeral"

  validation {
    condition     = contains(["Ephemeral", "Managed"], var.system_node_pool_os_disk_type)
    error_message = "The Operating System (OS) disk type for the System Node Pool is invalid. Possible values are `Ephemeral` and `Managed`."
  }
}

variable "system_node_pool_pod_subnet_id" {
  description = "(Optional) The ID of the Subnet where the pods in the system node pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "system_node_pool_vm_size" {
  description = "(Required) Specifies the Virtual Machine size (SKU) which should be used for the Virtual Machines used for the System Node Pool. Changing this forces a new resource to be created. Defaults to `Standard_D4ds_v4`."
  type        = string
  nullable    = false
  default     = "Standard_D4ds_v4"
}

variable "system_node_pool_vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the Kubernetes System Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

/* USER NODE POOL */

variable "user_node_pool_availability_zones" {
  description = "(Optional) A list of Availability Zones where the Nodes in this User Node Pool should be created in. Changing this forces a new resource to be created."
  type        = list(string)
  nullable    = false
  default     = ["1", "2", "3"]
}

variable "user_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "user_node_pool_enable_host_encryption" {
  description = "(Optional) Should the nodes in this User Node Pool have host encryption enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "user_node_pool_enable_node_public_ip" {
  description = "(Optional) Should each node have a Public IP Address? Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "user_node_pool_max_count" {
  description = "(Required) The maximum number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to `user_node_pool_min_count`. Defaults to 10."
  type        = number
  nullable    = false
  default     = 10
}

variable "user_node_pool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Defaults to 250. Changing this forces a new resource to be created."
  type        = number
  nullable    = false
  default     = 250
}

variable "user_node_pool_min_count" {
  description = "(Required) The minimum number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be less than or equal to `user_node_pool_max_count`. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
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

variable "user_node_pool_os_disk_size_gb" {
  description = "(Optional) The Agent Operating System disk size in GB. Changing this forces a new resource to be created."
  type        = number
  default     = null
}

variable "user_node_pool_os_disk_type" {
  description = "(Optional) The type of disk which should be used for the Operating System (OS) for the User Node Pool. Possible values are `Ephemeral` and `Managed`. Defaults to `Ephemeral`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Ephemeral"

  validation {
    condition     = contains(["Ephemeral", "Managed"], var.user_node_pool_os_disk_type)
    error_message = "The Operating System (OS) disk type for the User Node Pool is invalid. Possible values are `Ephemeral` and `Managed`."
  }
}

variable "user_node_pool_os_type" {
  description = "(Optional) The Operating System (OS) which should be used for this Use Node Pool. Changing this forces a new resource to be created. Possible values are `Linux` and `Windows`. Defaults to `Linux`."
  type        = string
  nullable    = false
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.user_node_pool_os_type)
    error_message = "The Operating System (OS) for the User Node Pool is invalid. Possible values are `Linux` and `Windows`."
  }
}

variable "user_node_pool_pod_subnet_id" {
  description = "(Optional) The ID of the Subnet where the pods in the User Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "user_node_pool_priority" {
  description = "(Optional) The priority for Virtual Machines (VM) within the Virtual Machine Scale Set that powers this User Node Pool. Possible values are `Regular` and `Spot`. Defaults to `Regular`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Regular"

  validation {
    condition     = contains(["Regular", "Spot"], var.user_node_pool_priority)
    error_message = "Invalid priority for Virtual Machines (VM) within the Virtual Machine Scale Set for the User Node Pool. Possible values are `Regular` and `Spot`."
  }
}

variable "user_node_pool_proximity_placement_group_id" {
  description = "(Optional) The ID of the Proximity Placement Group where the Virtual Machine Scale Set that powers this Node Pool will be placed. Changing this forces a new resource to be created."
  type        = string
  default     = null
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
