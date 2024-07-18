/* COMMON VARIABLES */

variable "use_random_suffix" {
  description = "(Required) If `true`, a random suffix is generated and added to the resource groups and its resources. If `false`, the `suffix` variable is used instead."
  type        = bool
  nullable    = false
  default     = true
}

variable "suffix" {
  description = "(Optional) A suffix for the name of the resource group and its resources. If variable `use_random_suffix` is `true`, this variable is ignored."
  type        = string
  nullable    = false
  default     = ""
}

variable "location" {
  description = "(Required) Specifies the location for the resource group and most of its resources. Defaults to `eastus2`"
  type        = string
  nullable    = false
  default     = "eastus2"
}

variable "tags" {
  description = "(Optional) Specifies tags for all the resources."
  nullable    = false
  default = {
    createdWith = "Terraform"
  }
}

/* RESOURCE GROUP */

variable "resource_group_name" {
  description = "(Required) The name of the resource group."
  type        = string
  nullable    = false
  default     = "rg-kaito-rag"
}

/* SSH KEY */

variable "ssh_key_name" {
  description = "(Required) Specifies the name of the SSH Key resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "sshkey-kaito-rag"
}

/* MANAGE IDENTITY */

variable "managed_identity_name" {
  description = "(Required) Specifies the name of the Managed Identity."
  type        = string
  nullable    = false
  default     = "id-kaito-rag"
}

/* STORAGE ACCOUNT */

variable "storage_account_name" {
  description = "(Required) Specifies the name of the Azure Virtual Network."
  type        = string
  nullable    = false
  default     = "stkaitorag"
}

variable "storage_account_tier" {
  description = "(Required) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. Changing this forces a new resource to be created. Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = can(regex("^(Standard|Premium)$", var.storage_account_tier))
    error_message = "Invalid account_tier. Valid options are `Standard` and `Premium`."
  }
}

variable "storage_account_replication_type" {
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. Changing this forces a new resource to be created when types `LRS`, `GRS` and `RAGRS` are changed to `ZRS`, `GZRS` or `RAGZRS` and vice versa. Defaults to `LRS`."
  type        = string
  nullable    = false
  default     = "LRS"

  validation {
    condition     = can(regex("^(LRS|GRS|RAGRS|ZRS|GZRS|RAGZRS)$", var.storage_account_replication_type))
    error_message = "Invalid account_replication_type. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  }
}

/* COSMOS DB */

variable "cosmos_name" {
  description = "(Required) Specifies the name of the Cosmos DB."
  type        = string
  nullable    = false
  default     = "cosmos-kaito-rag"
}

variable "cosmos_database_name" {
  description = "(Required) Specifies the name of the database in CosmosDB."
  type        = string
  nullable    = false
  default     = "kaito-rag"
}

variable "cosmos_container_name_chat_history" {
  description = "(Required) Specifies the name of the container in CosmosDB that will store the chat history indexed by `userId`."
  type        = string
  nullable    = false
  default     = "kaito-rag-chat-history"
}

/* LOG ANALYTICS WORKSPACE */

variable "log_analytics_workspace_name" {
  description = "(Required) Specifies the name of the Log Analytics Workspace."
  default     = "log-kaito"
  type        = string
  nullable    = false
}

/* APPLICATION INSIHGTS */

variable "appinsights_name" {
  description = "(Required) Specifies the name of the Application Insights."
  type        = string
  nullable    = false
  default     = "appi-kaito-rag"
}

/* OPEN AI */

variable "openai_name" {
  description = "(Required) Specifies the name of the Azure OpenAI servicee."
  type        = string
  nullable    = false
  default     = "oai-kaito-rag"
}

/* AZURE AI SEARCH */

variable "search_name" {
  description = "(Required) Specifies the name of the Azure AI Search."
  type        = string
  nullable    = false
  default     = "srch-kaito-rag"
}

variable "search_sku" {
  description = "(Required) Specifies the SKU of the Azure AI Search. Possible values are `free`, `basic`, `standard`, `standard2`, `standard3`, `storage_optimized_l1` and `storage_optimized_l2`. Defaults to `basic`."
  type        = string
  nullable    = false
  default     = "basic"

  validation {
    condition     = can(regex("^(free|basic|standard|standard2|standard3|storage_optimized_l1|storage_optimized_l2)$", var.search_sku))
    error_message = "Invalid SKU. Possible values are `free`, `basic`, `standard`, `standard2`, `standard3`, `storage_optimized_l1` and `storage_optimized_l2`."
  }
}

variable "search_sku_semantic_search" {
  description = "(Optional) Specifies the Semantic Search SKU which should be used for this Azure AI Search Service. Possible values are `free`, `standard` and `null` if no Semantic Search should be used. Defaults to `standard`."
  type        = string
  default     = "free"

  validation {
    condition     = var.search_sku != "free" || var.search_sku_semantic_search == null
    error_message = "Semantic Search SKU cannot be 'free' or 'standard' when the Azure AI Search SKU is 'free'."
  }

  validation {
    condition     = var.search_sku_semantic_search == null || can(regex("^(free|standard)$", var.search_sku_semantic_search))
    error_message = "Invalid Semantic Search SKU. Possible values are `free`, `standard` or `null` if no Semantic Search should be used."
  }
}

/* BOT */

variable "bot_name" {
  description = "(Required) Specifies the name of the Azure Bot. Defaults to `bot-kaito-rag`."
  type        = string
  nullable    = false
  default     = "bot-kaito-rag"
}

variable "bot_location" {
  description = "(Optional) Specifies the location of the Azure Bot. Currently an Azure Bot can only be deployed in the following locations: `global`, `westeurope` or `centralindia`. Defaults to `global`."
  type        = string
  nullable    = false
  default     = "global"

  validation {
    condition     = contains(["global", "westeurope", "centralindia"], var.bot_location)
    error_message = "The Azure Bot location is incorrect. Possible values are `global`, `westeurope` or `centralindia`."
  }
}

variable "bot_sku" {
  description = "(Optional) Specifies the sku of the Azure Bot. Defaults to `F0`."
  type        = string
  nullable    = false
  default     = "F0"

  validation {
    condition     = contains(["F0", "S1"], var.bot_sku)
    error_message = "The Azure Bot sku is incorrect. Possible values are `F0` or `S1`."
  }
}

variable "bot_type" {
  description = "(Optional) Specifies the type of the Azure Bot. Possible values are `SingleTenant`, `MultiTenant` or `functions`. Defaults to `SingleTenant`."
  type        = string
  nullable    = false
  default     = "SingleTenant"

  validation {
    condition     = contains(["SingleTenant", "MultiTenant", "UserAssignedMSI"], var.bot_type)
    error_message = "The Azure Bot type is incorrect. Possible values are `SingleTenant`, `MultiTenant` or `functions`."
  }
}

/* VIRTUAL NETWORK (VNet) */

variable "vnet_address_space" {
  description = "(Required) Specifies the address space (a.k.a. prefix) for the Azure Virtual Network."
  type        = list(string)
  nullable    = false
  default     = ["10.0.0.0/8"]
}

variable "vnet_name" {
  description = "(Required) Specifies the name of the Azure Virtual Network (eventually required by an Azure Kubernetes Service)."
  type        = string
  nullable    = false
  default     = "vnet-kaito-rag"
}

/* SUBNETS */

variable "subnet_address_prefix_api_server" {
  description = "(Required) Specifies the address prefix of the API Server subnet, when API Server VNet Integration is enabled."
  type        = list(string)
  nullable    = false
  default     = ["10.243.0.0/27"]
}

variable "subnet_address_prefix_bastion" {
  description = "(Required) Specifies the address prefix for the Bation subnet."
  type        = list(string)
  nullable    = false
  default     = ["10.243.2.0/24"]
}

variable "subnet_address_prefix_pod" {
  description = "(Required) Specifies the address prefix of the pod subnet. For instance, this subnet address prefix might be used by a jump-box Virtual Machine to manage the private Azure Kubernetes Service (AKS) cluster."
  type        = list(string)
  nullable    = false
  default     = ["10.242.0.0/16"]
}

variable "subnet_address_prefix_system_node_pool" {
  description = "(Required) Specifies the address prefix of the subnet that hosts the system node pool."
  type        = list(string)
  nullable    = false
  default     = ["10.240.0.0/16"]
}

variable "subnet_address_prefix_user_node_pool" {
  description = "(Required) Specifies the address prefix of the subnet that hosts the user node pool."
  type        = list(string)
  nullable    = false
  default     = ["10.241.0.0/16"]
}

variable "subnet_address_prefix_vm" {
  description = "(Required) Specifies the address prefix of the subnet that contains the jumpbox virtual machine and private endpoints."
  type        = list(string)
  nullable    = false
  default     = ["10.243.1.0/24"]
}

variable "subnet_name_api_server" {
  description = "(Required) Specifies the address prefix of the API Server subnet, when API Server VNet Integration is enabled."
  nullable    = false
  type        = string
  default     = "snet-api-server"
}

variable "subnet_name_bastion" {
  description = "(Required) Specifies the name of the Bastion subnet"
  type        = string
  nullable    = false
  default     = "snet-bastion"
}

variable "subnet_name_pod" {
  description = "(Required) Specifies the name of the pod subnet. For instance, this subnet might be used by a jump-box Virtual Machine to manage the private Azure Kubernetes Service (AKS) cluster."
  nullable    = false
  type        = string
  default     = "snet-pod"
}

variable "subnet_name_system_node_pool" {
  description = "(Required) Specifies the name of the subnet that hosts the system node pool."
  type        = string
  nullable    = false
  default     = "snet-system"
}

variable "subnet_name_user_node_pool" {
  description = "(Required) Specifies the name of the subnet that hosts the user node pool."
  type        = string
  nullable    = false
  default     = "snet-user"
}

variable "subnet_name_vm" {
  description = "(Required) Specifies the name of the subnet that contains the jumpbox virtual machine and private endpoints."
  type        = string
  nullable    = false
  default     = "snet-vm"
}

/* AZURE NAT Gateway */

variable "nat_gateway_idle_timeout_in_minutes" {
  description = "(Optional) The idle timeout which should be used in minutes. Defaults to 4."
  type        = number
  nullable    = false
  default     = 4
}

variable "nat_gateway_name" {
  description = "(Required) Specifies the name of the NAT Gateway."
  type        = string
  nullable    = false
  default     = "ng-kaito-rag"
}

variable "nat_gateway_sku" {
  description = "(Optional) The SKU which should be used for the NAT Gateway. At this time the only supported value is `Standard`. Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"
}

variable "nat_gateway_zones" {
  description = "(Optional) A list of Availability Zones in which this NAT Gateway should be located. Changing this forces a new NAT Gateway to be created."
  type        = list(string)
  nullable    = false
  default     = ["1"]
}

/* AZURE CONTAINER REGISTRY (ACR) */

variable "acr_admin_enabled" {
  description = "(Optional) Specifies whether the admin user is enabled. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "acr_georeplication_locations" {
  description = "(Optional) A list of Azure locations where the Azure Container Registry (ACR) should be geo-replicated."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "acr_name" {
  description = "(Required) Specifies the name of the Azure Container Registry (ACR)."
  type        = string
  nullable    = false
  default     = "crkaitorag"
}

variable "acr_sku" {
  description = "(Required) The SKU which should be used for the Azure Container Registry (ACR). At this time the only supported value is `Standard`. Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The container registry sku is invalid."
  }
}

/* AZURE KUBERNETES SERVICE (AKS) */

variable "aks_dns_zone_name" {
  description = "Specifies the name of the DNS zone."
  type        = string
  default     = null
}

variable "aks_dns_zone_resource_group_name" {
  description = "Specifies the name of the resource group that contains the DNS zone."
  type        = string
  default     = null
}



variable "aks_admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "aks_admin_username" {
  description = "(Required) Specifies the Admin Username for the Azure Kubernetes Service (AKS) cluster worker nodes. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "azureadmin"
}

variable "aks_annotations_allowed" {
  description = "(Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric."
  type        = string
  default     = null
}

variable "aks_authorized_ip_ranges" {
  description = "(Optional) Set of authorized IP ranges to allow access to API server."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "aks_automatic_channel_upgrade" {
  description = "(Optional) The upgrade channel for this Kubernetes Cluster. Possible values are `patch`, `rapid`, and `stable`. Defaults to `stable`."
  type        = string
  nullable    = false
  default     = "stable"

  validation {
    condition     = contains(["patch", "rapid", "stable"], var.aks_automatic_channel_upgrade)
    error_message = "The upgrade mode is invalid."
  }
}

variable "aks_azure_policy_enabled" {
  description = "(Optional) Should the Azure Policy Add-On be enabled? For more details please visit Understand Azure Policy for Azure Kubernetes Service (AKS). Defaults to `false`."
  type        = bool
  default     = true
}

variable "aks_azure_rbac_enabled" {
  description = "(Optional) Is Role Based Access Control based on Azure AD enabled? Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_dns_service_ip" {
  description = "(Optional) Specifies the DNS service IP."
  type        = string
  nullable    = false
  default     = "172.16.0.10"
}

variable "aks_enable_rbac_cluster_admin_assignment" {
  description = "(Optional) Indicates wheter the Azure Kubernetes Service (AKS) ACluster Admin role should be assigned to the list of principal IDs defined in `aks_admin_group_object_ids`. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_http_application_routing_enabled" {
  description = "(Optional) Should HTTP Application Routing be enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_image_cleaner_enabled" {
  description = "(Optional) Specifies whether Image Cleaner is enabled. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_image_cleaner_interval_hours" {
  description = "(Optional) Specifies the interval in hours when images should be cleaned up. Defaults to 48 (hours)."
  type        = number
  nullable    = false
  default     = 48
}

variable "aks_keda_enabled" {
  description = "(Optional) Specifies whether Kubernetes Event-driven Autoscaling (KEDA) Autoscaler  can be used for workloads. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_kubernetes_version" {
  description = "(Optional) Specifies the AKS Kubernetes version. Defaults to `1.29.2`."
  type        = string
  nullable    = false
  default     = "1.29.5"
}

variable "aks_labels_allowed" {
  description = "(Optional) Specifies a comma-separated list of additional Kubernetes label keys that will be used in the resource's labels metric."
  type        = string
  default     = null
}

variable "aks_name" {
  description = "(Required) Specifies the name of the Azure Kubernetes Service (AKS) cluster."
  type        = string
  nullable    = false
  default     = "aks-kaito-rag"
}

variable "aks_network_mode" {
  description = "(Optional) Network mode to be used with Azure CNI (Container Network Interface). Possible values are `bridge` and `transparent`. Changing this forces a new resource to be created. Defaults to `transparent`."
  nullable    = false
  type        = string
  default     = "transparent"

  validation {
    condition     = contains(["bridge", "transparent"], var.aks_network_mode)
    error_message = "The network mode is invalid. Possible values are `bridge` and `transparent`."
  }
}

variable "aks_network_plugin" {
  description = "(Optional) Specifies the network plugin of the Azure Kubernetes Service (AKS) cluster. Possible values are `azure`, `kubenet` or `none`. Defaults to `azure`."
  type        = string
  nullable    = false
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.aks_network_plugin)
    error_message = "The network plugin is invalid. Possible values are `azure`, `kubenet` or `none`."
  }
}

variable "aks_network_plugin_mode" {
  description = "(Optional) Specifies the network plugin mode used for building the Kubernetes network. Possible values are `overlay` or `null`. Defauls is `overlay`."
  type        = string
  nullable    = true
  default     = "overlay"

  validation {
    condition     = var.aks_network_plugin_mode == null ? true : contains(["overlay"], var.aks_network_plugin_mode)
    error_message = "The network plugin mode value is incorrect. Possible values are `overlay` or `null`."
  }
}

variable "aks_network_policy" {
  description = " (Optional) Sets up network policy to be used with Azure CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are `calico`, `azure` and `cilium`. Defaults to `azure`."
  type        = string
  nullable    = false
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "cilium"], var.aks_network_policy)
    error_message = "The upgrade policy is invalid."
  }
}

variable "aks_oidc_issuer_enabled" {
  description = "(Optional) Enable or Disable the OpenID Connect (OIDC) issuer URL. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_oms_agent_addon_msi_auth_for_monitoring_enabled" {
  description = "(Optional) Specifies whether to use Managed Service Identity (MSI) authentication for the Operation Management Suite Agent (OMS Agent). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_open_service_mesh_enabled" {
  description = "(Optional) Is Open Service Mesh enabled? For more details, please visit Open Service Mesh for Azure Kubernetes Service (AKS). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_outbound_type" {
  description = "(Optional) The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are `loadBalancer`, `userDefinedRouting`, `userAssignedNATGateway` or `managedNATGateway`. Defaults to `loadBalancer`."
  type        = string
  nullable    = false
  default     = "userAssignedNATGateway"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "userAssignedNATGateway", "managedNATGateway"], var.aks_outbound_type)
    error_message = "The outbound type is invalid."
  }
}

variable "aks_pod_cidr" {
  description = "(Optional) Specifies the Classless Inter-Domain Routing (CIDR) to use for pod IP addresses. This field can only be set when `network_plugin` is set to `kubenet` or `network_plugin_mode` is set to `overlay`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "172.0.0.0/16"
}

variable "aks_private_cluster_enabled" {
  description = "(Optional) Should this Kubernetes Cluster have its API server only exposed on internal IP addresses? This provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_service_cidr" {
  description = "(Optional) Specifies the service Classless Inter-Domain Routing (CIDR) or Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "172.16.0.0/16"
}

variable "aks_sku" {
  description = "(Optional) The SKU Tier that should be used for this Kubernetes Cluster. Possible values are `Free` and `Paid` (which includes the Uptime SLA). Defaults to `Free`."
  type        = string
  nullable    = false
  default     = "Free"

  validation {
    condition     = contains(["Free", "Paid"], var.aks_sku)
    error_message = "The sku tier is invalid."
  }
}

// System Node Pool

variable "aks_system_node_pool_availability_zones" {
  description = "(Optional) Specifies the availability zones of the System Node Pool."
  type        = list(string)
  nullable    = false
  default     = ["1", "2", "3"]
}

variable "aks_system_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `false`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_system_node_pool_enable_host_encryption" {
  description = "(Optional) Should the nodes in this Node Pool have host encryption enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_system_node_pool_enable_node_public_ip" {
  description = "(Optional) Should each node have a Public IP Address? Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_system_node_pool_max_count" {
  description = "(Required) The maximum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to `min_count`. Defaults to 10."
  type        = number
  nullable    = false
  default     = 30
}

variable "aks_system_node_pool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created. Defaults to `50`."
  type        = number
  nullable    = false
  default     = 30
}

variable "aks_system_node_pool_min_count" {
  description = "(Required) The minimum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be less than or equal to `max_count`. Defaults to 3."
  type        = number
  nullable    = false
  default     = 1
}

variable "aks_system_node_pool_name" {
  description = "(Optional) Specifies the name of the System Node Pool. Default is `system`."
  type        = string
  nullable    = false
  default     = "system"
}

variable "aks_system_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be a value in the range `min_count - max_count`. Defaults to 3."
  type        = number
  nullable    = false
  default     = 1
}

variable "aks_system_node_pool_node_labels" {
  description = "(Optional) A list of Kubernetes taints which should be applied to nodes in the agent pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "aks_system_node_pool_only_critical_addons_enabled" {
  description = "(Optional) Enabling this option will taint default node pool with `CriticalAddonsOnly=true:NoSchedule` taint. The `temporary_name_for_rotation` value must be specified when changing this property. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_system_node_pool_os_disk_type" {
  description = "(Optional) The type of disk which should be used for the Operating System (OS). Possible values are `Ephemeral` and `Managed`. Defaults to `Ephemeral`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Ephemeral"

  validation {
    condition     = contains(["Ephemeral", "Managed"], var.aks_system_node_pool_os_disk_type)
    error_message = "The Operating System (OS) disk type is invalid. Possible values are `Ephemeral` and `Managed`."
  }
}

variable "aks_system_node_pool_vm_size" {
  description = "(Optional) Specifies the Virtual machine size of the System Node Pool. Defaults to `Standard_D4ds_v4`."
  type        = string
  nullable    = false
  default     = "Standard_D4ds_v4"
}

variable "aks_vertical_pod_autoscaler_enabled" {
  description = "(Optional) Specifies whether Vertical Pod Autoscaler should be enabled. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_vnet_integration_enabled" {
  description = "(Optional) Should API Server VNet Integration be enabled? For more details please visit Use API Server VNet Integration. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_workload_identity_enabled" {
  description = "(Optional) Specifies whether Microsoft Enbtra (former Azure Active Directory or Azure AD) Workload Identity should be enabled for the Cluster. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

// User Node Pool

variable "aks_user_node_pool_availability_zones" {
  description = "(Optional) A list of Availability Zones where the Nodes in this User Node Pool should be created in. Changing this forces a new resource to be created."
  type        = list(string)
  nullable    = false
  default     = ["1", "2", "3"]
}

variable "aks_user_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_user_node_pool_enable_host_encryption" {
  description = "(Optional) Should the nodes in this User Node Pool have host encryption enabled? Defaults to `false`."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_user_node_pool_enable_node_public_ip" {
  description = "(Optional) Should each node have a Public IP Address? Defaults to `false`. Changing this forces a new resource to be created."
  type        = bool
  nullable    = false
  default     = false
}

variable "aks_user_node_pool_max_count" {
  description = "(Required) The maximum number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to `user_node_pool_min_count`."
  type        = number
  nullable    = false
  default     = 10
}

variable "aks_user_node_pool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 50
}

variable "aks_user_node_pool_min_count" {
  description = "(Required) The minimum number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be less than or equal to `user_node_pool_max_count`."
  type        = number
  nullable    = false
  default     = 1
}

variable "aks_user_node_pool_name" {
  description = "(Required) Specifies the name of the User Node Pool. Default is `user`."
  type        = string
  nullable    = false
  default     = "user"
}

variable "aks_user_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be a value in the range `user_node_pool_min_count - user_node_pool_max_count`."
  type        = number
  nullable    = false
  default     = 1
}

variable "aks_user_node_pool_node_labels" {
  description = "(Optional) A map of Kubernetes taints which should be applied to nodes in this User Node Pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "aks_user_node_pool_node_taints" {
  description = "(Optional) A list of Kubernetes taints which should be applied to nodes in the User Node Pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "aks_user_node_pool_os_disk_size_gb" {
  description = "(Optional) The Agent Operating System disk size in GB. Changing this forces a new resource to be created."
  type        = number
  default     = null
}

variable "aks_user_node_pool_os_disk_type" {
  description = "(Optional) The type of disk which should be used for the Operating System (OS) for the User Node Pool. Possible values are `Ephemeral` and `Managed`. Defaults to `Ephemeral`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Ephemeral"

  validation {
    condition     = contains(["Ephemeral", "Managed"], var.aks_user_node_pool_os_disk_type)
    error_message = "The Operating System (OS) disk type for the User Node Pool is invalid. Possible values are `Ephemeral` and `Managed`."
  }
}

variable "aks_user_node_pool_os_type" {
  description = "(Optional) The Operating System (OS) which should be used for this Use Node Pool. Changing this forces a new resource to be created. Possible values are `Linux` and `Windows`. Defaults to `Linux`."
  type        = string
  nullable    = false
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.aks_user_node_pool_os_type)
    error_message = "The Operating System (OS) for the User Node Pool is invalid. Possible values are `Linux` and `Windows`."
  }
}

variable "aks_user_node_pool_pod_subnet_id" {
  description = "(Optional) The ID of the Subnet where the pods in the User Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "aks_user_node_pool_priority" {
  description = "(Optional) The priority for Virtual Machines (VM) within the Virtual Machine Scale Set that powers this User Node Pool. Possible values are `Regular` and `Spot`. Defaults to `Regular`. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "Regular"

  validation {
    condition     = contains(["Regular", "Spot"], var.aks_user_node_pool_priority)
    error_message = "Invalid priority for Virtual Machines (VM) within the Virtual Machine Scale Set for the User Node Pool. Possible values are `Regular` and `Spot`."
  }
}

variable "aks_user_node_pool_proximity_placement_group_id" {
  description = "(Optional) The ID of the Proximity Placement Group where the Virtual Machine Scale Set that powers this Node Pool will be placed. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "aks_user_node_pool_vm_size" {
  description = "(Required) Specifies the Virtual Machine size (SKU) which should be used for the Virtual Machines used for the User Node Pool. Changing this forces a new resource to be created. Defaults to `Standard_D4ds_v4`."
  type        = string
  nullable    = false
  default     = "Standard_D4ds_v4"
}

variable "aks_user_node_pool_vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the User Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

/* KAITO */

variable "kaito_aks_namespace" {
  description = "(Optional) Specifies the namespace of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag`."
  type        = string
  nullable    = false
  default     = "kaito-rag"
}

variable "kaito_instance_type_vm_size" {
  description = "(Optional) Specifies the GPU node SKU. This field defaults to `Standard_NC6s_v3` if not specified."
  type        = string
  default     = "Standard_NC6s_v3"
}

variable "kaito_service_account_name" {
  description = "(Optional) Specifies the name of the service account of the workload application that accesses the Azure OpenAI Service. Defaults to `kaito-rag-sa`."
  type        = string
  nullable    = false
  default     = "kaito-rag-sa"
}

# # variable "workload_managed_identity_client_id" {
# #   description = "(Required) Specifies the client id of the workload user-defined managed identity."
# #   type        = string
# #   nullable    = false
# # }
