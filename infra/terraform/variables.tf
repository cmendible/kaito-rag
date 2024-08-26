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
  description = "(Required) Specifies the location for the resource group and most of its resources. Defaults to `westeurope`"
  type        = string
  nullable    = false
  default     = "westeurope"
}

variable "tags" {
  description = "(Optional) Specifies tags for all the resources."
  nullable    = false
  default = {
    createdUsing = "Terraform"
  }
}

/* RESOURCE GROUP */

variable "resource_group_name" {
  description = "(Required) The name of the resource group."
  type        = string
  nullable    = false
  default     = "rg-kaito-rag"
}

## ---- SPECIFIC RESOURCES & SERVICES ---- ##

/* AI SEARCH */

variable "search_name" {
  description = "(Required) Specifies the name of the Azure AI Search."
  type        = string
  nullable    = false
  default     = "srch-kaito-rag"
}

variable "search_location" {
  description = "(Optional) Specifies the location of the Azure AI Search service. If `null`, then the location of the resource group is used. Defaults to `null`."
  type        = string
  nullable    = true
  default     = null
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

variable "search_local_authentication_enabled" {
  description = "(Optional) Specifies whether or not local authentication should be enabled for this Azure AI Search Service. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}


/* AZURE KUBERNETES SERVICE (AKS) */

variable "aks_name" {
  description = "(Required) Specifies the name of the SSH Key resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "aks-kaito-rag"
}

variable "aks_sku" {
  description = "(Optional) The SKU Tier that should be used for this Azure Kubernetes Service (AKS) Cluster. Possible values are `Free`, `Standard`, `Premium` (which includes the Uptime SLA). Defaults to `Standard`."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.aks_sku)
    error_message = "The SKU tier is invalid. Possible values are `Free`, `Standard`. `Premium`."
  }
}

variable "aks_use_node_resource_group" {
  description = "(Optional) Specifies wheter the AKS nodes be located on a specific resource group or not. The resource group name will be the same as the `resource_group_name` variable plus `-nodes`. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_kubernetes_version" {
  description = "(Required) Specifies the AKS Kubernetes version. Defaults to `1.30`."
  type        = string
  nullable    = false
  default     = "1.30"
}

variable "aks_admin_username" {
  description = "(Required) Specifies the Admin Username for the Azure Kubernetes Service (AKS) cluster worker nodes. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "azureadmin"
}

variable "aks_dns_prefix" {
  description = "(Optional) DNS prefix specified when creating the managed cluster. Changing this forces a new resource to be created."
  type        = string
  default     = "dns-kaito-rag"
}

variable "aks_oms_agent_addon_msi_auth_for_monitoring_enabled" {
  description = "(Optional) Specifies whether to use Managed Service Identity (MSI) authentication for the Operation Management Suite Agent (OMS Agent). Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_system_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within the System Node Pool. Valid values are between 0 and 1000. Defaults to 1."
  type        = number
  nullable    = false
  default     = 1
}

variable "aks_system_node_pool_vm_size" {
  description = "(Required) Specifies the Virtual Machine size (SKU) which should be used for the Virtual Machines used for the System Node Pool. Changing this forces a new resource to be created. Defaults to `Standard_D2s_v5`."
  type        = string
  nullable    = false
  default     = "Standard_D2s_v5"
}

variable "aks_user_node_pool_enable_auto_scaling" {
  description = "(Optional) Whether to enable auto-scaler. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "aks_user_node_pool_name" {
  description = "(Required) Specifies the name of the User Node Pool. Default is `user`."
  type        = string
  nullable    = false
  default     = "user"
}

variable "aks_user_node_pool_node_count" {
  description = "(Optional) The initial number of nodes which should exist within this User Node Pool. Valid values are between 0 and 1000 and must be a value in the range `user_node_pool_min_count - user_node_pool_max_count`. Defaults to 1."
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

variable "aks_admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  type        = list(string)
  nullable    = false
  default     = []
}


/* APP CONFIGURATION */

variable "appcs_name" {
  description = "(Required) Specifies the name of the Azure App Configuration."
  type        = string
  nullable    = false
  default     = "appcs-kaito-rag"
}

variable "appcs_sku" {
  description = "(Required) Specifies the SKU of the Azure App Configuration. Possible values are `free` and `standard`. Defaults to `free`."
  type        = string
  nullable    = false
  default     = "free"

  validation {
    condition     = contains(["free", "standard"], var.appcs_sku)
    error_message = "The Azure App Configuration SKU is incorrect. Possible values are `free` and `standard`."
  }
}

variable "appcs_local_authentication_enabled" {
  description = "(Optional) Specifies whether or not local authentication should be enabled for this Azure App Configuration resource. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

variable "appcs_soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This field only works for standard sku. This value can be between 1 and 7 days. Defaults to 7. Changing this forces a new resource to be created."
  type        = number
  nullable    = false
  default     = 7

  validation {
    condition     = var.appcs_soft_delete_retention_days >= 1 && var.appcs_soft_delete_retention_days <= 7
    error_message = "The soft delete retention days must be between 1 and 7 days and only works for the standard SKU."
  }
}

variable "appcs_public_network_access" {
  description = "(Optional) The Public Network Access setting of the App Configuration. Possible values are `Enabled` and `Disabled`. Defaults to `Enabled`."
  type        = string
  nullable    = false
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.appcs_public_network_access)
    error_message = "The Public Network Access setting of the App Configuration is incorrect. Possible values are `Enabled` and `Disabled`."
  }
}

variable "appcs_label" {
  description = "(Optional) Specifies the label to use for values in the Azure App Configuration."
  type        = string
  nullable    = true
  default     = null
}


/* APPLICATION INSIHGTS */

variable "appinsights_name" {
  description = "(Required) Specifies the name of the Application Insights."
  type        = string
  nullable    = false
  default     = "appi-kaito-rag"
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

variable "bot_backend_endpoint" {
  description = "(Required) Specifies the backend endpoint of the Azure Bot. This value is also known as the messaging endpoint."
  type        = string
  nullable    = false
}


/* COSMOS DB */

variable "cosmos_name" {
  description = "(Required) Specifies the name of the Cosmos DB."
  type        = string
  nullable    = false
  default     = "cosmos-kaito-rag"
}

variable "cosmos_location" {
  description = "(Optional) Specifies the location of the Cosmos DB service. If `null`, then the location of the resource group is used. Defaults to `null`."
  type        = string
  nullable    = true
  default     = null
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


/* KAITO */

variable "kaito_use_upstream_version" {
  description = "(Optional) If `true`, the upstream version of Kaito from GitHub will be used. If `false`, the Azure managed Kaito version is used. Defaults to `true`."
  type        = bool
  nullable    = false
  default     = true
}

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

variable "kaito_ai_model" {
  description = "(Required) Specifies the name of the AI model to deploy with Kaito. Not all models are supported. Please refer to the Kaito documentation for more information here: https://github.com/Azure/kaito/blob/main/presets/README.md"
  type        = string
  nullable    = false
}


/* KEY VAULT */

variable "key_vault_name" {
  description = "(Required) Specifies the name of the Key Vault."
  type        = string
  nullable    = false
  default     = "kv-kaito-rag"
}

variable "key_vault_soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. Default is 7 days."
  type        = number
  nullable    = false
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "The number of days that items should be retained for once soft-deleted should be between 7 and 90 days."
  }
}

variable "key_vault_sku" {
  description = "(Required) The SKU name of the Key Vault. Possible values are `Standard` and `Premium`. Default is `Standard`."
  type        = string
  nullable    = true
  default     = "Standard"

  validation {
    condition     = var.key_vault_sku == "Standard" || var.key_vault_sku == "Premium"
    error_message = "The SKU name of the Key Vault must be either `Standard` or `Premium`."
  }
}


/* LOG ANALYTICS WORKSPACE */

variable "log_analytics_workspace_name" {
  description = "(Required) Specifies the name of the Log Analytics Workspace."
  default     = "log-kaito"
  type        = string
  nullable    = false
}


/* MANAGE IDENTITY */

variable "managed_identity_name" {
  description = "(Required) Specifies the name of the Managed Identity."
  type        = string
  nullable    = false
  default     = "id-kaito-rag"
}


/* NETWORK SECURITY GROUP */

variable "nsg_name" {
  description = "(Required) Specifies the name of the Azure Network Security Group (NSG)."
  type        = string
  nullable    = false
  default     = "nsg-kaito-rag"
}


/* OPEN AI */

variable "openai_name" {
  description = "(Required) Specifies the name of the Azure OpenAI servicee."
  type        = string
  nullable    = false
  default     = "oai-kaito-rag"
}

variable "openai_location" {
  description = "(Optional) Specifies the location of the Azure OpenAI service. If `null`, then the location of the resource group is used. Defaults to `null`."
  type        = string
  nullable    = true
  default     = null
}


/* SSH KEY */

variable "ssh_key_name" {
  description = "(Required) Specifies the name of the SSH Key resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
  default     = "sshkey-kaito-rag"
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


/* VIRTUAL NETWORK (VNet) and SUBNETS */

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

variable "subnet_name" {
  description = "(Required) Specifies the name of the Azure Subnet."
  type        = string
  nullable    = false
  default     = "snet-kaito-rag"
}

variable "subnet_address_space" {
  description = "(Required) The address space that is used the Azure Subnet. Defaults to `10.1.1.0/24`."
  type        = list(string)
  nullable    = false
  default     = ["10.1.1.0/24"]
}
