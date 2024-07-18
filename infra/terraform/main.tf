data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_id" "random" {
  byte_length = 8
}

locals {
  suffix                         = lower(trimspace(var.use_random_suffix ? substr(lower(random_id.random.hex), 1, 5) : var.suffix))
  name_suffix                    = local.suffix != null ? "-${local.suffix}" : ""
  name_resource_group            = "${var.resource_group_name}${local.name_suffix}"
  name_log_analytics_workspace   = "${var.log_analytics_workspace_name}${local.name_suffix}"
  name_vnet                      = "${var.vnet_name}${local.name_suffix}"
  name_nat_gateway               = "${var.nat_gateway_name}${local.name_suffix}"
  name_container_registry        = "${var.acr_name}${local.suffix}"
  name_aks                       = "${var.aks_name}${local.name_suffix}"
  name_appinsights               = "${var.appinsights_name}${local.name_suffix}"
  name_openai                    = "${var.openai_name}${local.name_suffix}"
  name_manage_identity           = "${var.managed_identity_name}${local.name_suffix}"
  name_search                    = "${var.search_name}${local.name_suffix}"
  name_storage_account           = "${var.storage_account_name}${local.suffix}"
  name_bot                       = "${var.bot_name}${local.name_suffix}"
  name_ssk_key                   = "${var.ssh_key_name}${local.name_suffix}"
  network_plugin_mode            = var.aks_network_plugin_mode == null ? "" : lower(var.aks_network_plugin_mode)
  is_network_plugin_mode_overlay = local.network_plugin_mode == "overlay"
  is_network_plugin_azure        = lower(var.aks_network_plugin) == "azure"
  kaito_identity_name            = "ai-toolchain-operator-${lower(local.name_aks)}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.name_resource_group
  location = var.location
  tags     = var.tags
}

module "mi" {
  source              = "./modules/mi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.name_manage_identity
}

module "openai" {
  source              = "./modules/aoai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = local.name_openai
  principal_id        = module.mi.principal_id
  tags                = var.tags
}

module "search" {
  source              = "./modules/search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = local.name_search
  sku                 = var.search_sku
  sku_semantic_search = var.search_sku_semantic_search
  principal_id        = module.mi.principal_id
  tags                = var.tags
}

module "st" {
  source                   = "./modules/st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  name                     = local.name_storage_account
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = var.tags
}

module "cosmos" {
  source                      = "./modules/cosmos"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = var.location
  name                        = var.cosmos_name
  database_name               = var.cosmos_database_name
  container_name_chat_history = var.cosmos_container_name_chat_history
  tags                        = var.tags

}

module "log_analytics_workspace" {
  source              = "./modules/log"
  name                = local.name_log_analytics_workspace
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

module "application_insights" {
  source                     = "./modules/appi"
  name                       = local.name_appinsights
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = var.tags
}

module "bot" {
  source                                   = "./modules/bot"
  name                                     = local.name_bot
  resource_group_name                      = azurerm_resource_group.rg.name
  bot_location                             = var.bot_location
  sku                                      = var.bot_sku
  bot_type                                 = var.bot_type
  bot_user_assigned_identity_location      = var.location
  tags                                     = var.tags
  application_insights_id                  = module.application_insights.appi_id
  application_insights_app_id              = module.application_insights.appi_aap_id
  application_insights_instrumentation_key = module.application_insights.appi_instrumentation_key
}

module "virtual_network" {
  source                     = "./modules/vnet"
  name                       = local.name_vnet
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  address_space              = var.vnet_address_space
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = var.tags

  subnets = [
    {
      name : var.subnet_name_system_node_pool
      address_prefixes : var.subnet_address_prefix_system_node_pool
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : null
    },
    {
      name : var.subnet_name_user_node_pool
      address_prefixes : var.subnet_address_prefix_user_node_pool
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : null
    },
    {
      name : var.subnet_name_api_server
      address_prefixes : var.subnet_address_prefix_api_server
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : "Microsoft.ContainerService/managedClusters"
    },
    {
      name : var.subnet_name_vm
      address_prefixes : var.subnet_address_prefix_vm
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : null
    },
    {
      name : var.subnet_name_bastion
      address_prefixes : var.subnet_address_prefix_bastion
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : null
    },
    !local.is_network_plugin_mode_overlay ? {
      name : var.subnet_name_pod
      address_prefixes : var.subnet_address_prefix_pod
      private_endpoint_network_policies : "Enabled"
      private_link_service_network_policies_enabled : false
      delegation : "Microsoft.ContainerService/managedClusters"
    } : null
  ]
}

module "nat_gateway" {
  source                  = "./modules/ng"
  name                    = local.name_nat_gateway
  resource_group_name     = azurerm_resource_group.rg.name
  location                = var.location
  sku                     = var.nat_gateway_sku
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
  zones                   = var.nat_gateway_zones
  tags                    = var.tags
  subnet_ids              = module.virtual_network.subnet_ids
}

module "container_registry" {
  source                     = "./modules/acr"
  name                       = local.name_container_registry
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  sku                        = var.acr_sku
  admin_enabled              = var.acr_admin_enabled
  georeplication_locations   = var.acr_georeplication_locations
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = var.tags
}

module "ssh" {
  source              = "./modules/ssh"
  resource_group_name = azurerm_resource_group.rg.name
  resource_group_id   = azurerm_resource_group.rg.id
  location            = var.location
  name                = local.name_ssk_key
  tags                = var.tags
}

data "azurerm_dns_zone" "dns_zone" {
  count               = var.aks_dns_zone_name != null && var.aks_dns_zone_resource_group_name != null ? 1 : 0
  name                = var.aks_dns_zone_name
  resource_group_name = var.aks_dns_zone_resource_group_name
}

module "aks" {
  source                           = "./modules/aks"
  location                         = var.location
  resource_group_id                = azurerm_resource_group.rg.id
  resource_group_name              = azurerm_resource_group.rg.name
  tenant_id                        = data.azurerm_client_config.current.tenant_id
  name                             = local.name_aks
  sku                              = var.aks_sku
  kubernetes_version               = var.aks_kubernetes_version
  tags                             = var.tags
  admin_username                   = var.aks_admin_username
  ssh_public_key                   = module.ssh.public_key
  log_analytics_workspace_id       = module.log_analytics_workspace.id
  msi_auth_for_monitoring_enabled  = var.aks_oms_agent_addon_msi_auth_for_monitoring_enabled
  dns_prefix                       = lower(local.name_aks)
  private_cluster_enabled          = var.aks_private_cluster_enabled
  automatic_channel_upgrade        = var.aks_automatic_channel_upgrade
  workload_identity_enabled        = var.aks_workload_identity_enabled
  oidc_issuer_enabled              = var.aks_oidc_issuer_enabled
  open_service_mesh_enabled        = var.aks_open_service_mesh_enabled
  image_cleaner_enabled            = var.aks_image_cleaner_enabled
  image_cleaner_interval_hours     = var.aks_image_cleaner_interval_hours
  azure_policy_enabled             = var.aks_azure_policy_enabled
  http_application_routing_enabled = var.aks_http_application_routing_enabled

  /* Network */
  dns_service_ip      = var.aks_dns_service_ip
  service_cidr        = var.aks_service_cidr
  pod_cidr            = var.aks_pod_cidr
  network_plugin      = var.aks_network_plugin
  network_plugin_mode = local.is_network_plugin_azure ? local.network_plugin_mode : null
  network_mode        = local.is_network_plugin_azure ? var.aks_network_mode : null
  network_policy      = var.aks_network_policy
  outbound_type       = var.aks_outbound_type

  /* Role Based Access Control - RBAC */
  admin_group_object_ids                   = var.aks_admin_group_object_ids
  azure_rbac_enabled                       = var.aks_azure_rbac_enabled
  enable_aks_rbac_cluster_admin_assignment = var.aks_enable_rbac_cluster_admin_assignment

  /* Workload Autoscaler Profile */
  keda_enabled                    = var.aks_keda_enabled
  vertical_pod_autoscaler_enabled = var.aks_vertical_pod_autoscaler_enabled

  /* Monitoring Metrics */
  annotations_allowed = var.aks_annotations_allowed
  labels_allowed      = var.aks_labels_allowed

  /* System Node Pool */
  system_node_pool_name                         = var.aks_system_node_pool_name
  system_node_pool_vm_size                      = var.aks_system_node_pool_vm_size
  system_node_pool_vnet_subnet_id               = module.virtual_network.subnet_ids[var.subnet_name_system_node_pool]
  system_node_pool_pod_subnet_id                = !local.is_network_plugin_mode_overlay ? module.virtual_network.subnet_ids[var.subnet_name_pod] : null
  system_node_pool_availability_zones           = var.aks_system_node_pool_availability_zones
  system_node_pool_node_labels                  = var.aks_system_node_pool_node_labels
  system_node_pool_only_critical_addons_enabled = var.aks_system_node_pool_only_critical_addons_enabled
  system_node_pool_enable_auto_scaling          = var.aks_system_node_pool_enable_auto_scaling
  system_node_pool_enable_host_encryption       = var.aks_system_node_pool_enable_host_encryption
  system_node_pool_enable_node_public_ip        = var.aks_system_node_pool_enable_node_public_ip
  system_node_pool_max_pods                     = var.aks_system_node_pool_max_pods
  system_node_pool_max_count                    = var.aks_system_node_pool_max_count
  system_node_pool_min_count                    = var.aks_system_node_pool_min_count
  system_node_pool_node_count                   = var.aks_system_node_pool_node_count
  system_node_pool_os_disk_type                 = var.aks_system_node_pool_os_disk_type

  /* User Node Pool */
  user_node_pool_name                         = var.aks_user_node_pool_name
  user_node_pool_vm_size                      = var.aks_user_node_pool_vm_size
  user_node_pool_vnet_subnet_id               = module.virtual_network.subnet_ids[var.subnet_name_user_node_pool]
  user_node_pool_pod_subnet_id                = !local.is_network_plugin_mode_overlay ? module.virtual_network.subnet_ids[var.subnet_name_pod] : null
  user_node_pool_availability_zones           = var.aks_user_node_pool_availability_zones
  user_node_pool_node_labels                  = var.aks_user_node_pool_node_labels
  user_node_pool_node_taints                  = var.aks_user_node_pool_node_taints
  user_node_pool_enable_auto_scaling          = var.aks_user_node_pool_enable_auto_scaling
  user_node_pool_enable_host_encryption       = var.aks_user_node_pool_enable_host_encryption
  user_node_pool_enable_node_public_ip        = var.aks_user_node_pool_enable_node_public_ip
  user_node_pool_max_pods                     = var.aks_user_node_pool_max_pods
  user_node_pool_max_count                    = var.aks_user_node_pool_max_count
  user_node_pool_min_count                    = var.aks_user_node_pool_min_count
  user_node_pool_node_count                   = var.aks_user_node_pool_node_count
  user_node_pool_os_disk_type                 = var.aks_user_node_pool_os_disk_type
  user_node_pool_os_disk_size_gb              = var.aks_user_node_pool_os_disk_size_gb
  user_node_pool_os_type                      = var.aks_user_node_pool_os_type
  user_node_pool_priority                     = var.aks_user_node_pool_priority
  user_node_pool_proximity_placement_group_id = var.aks_user_node_pool_proximity_placement_group_id

  web_app_routing = {
    enabled     = true
    dns_zone_id = length(data.azurerm_dns_zone.dns_zone) > 0 ? element(data.azurerm_dns_zone.dns_zone[*].id, 0) : ""
  }

  depends_on = [
    module.nat_gateway,
    module.container_registry
  ]
}

// Gets the Resource Group name of the AKS cluster node
data "azurerm_resource_group" "node_resource_group" {
  name = module.aks.node_resource_group

  depends_on = [module.aks]
}

/* KAITO - Kubernetes AI Toolchain Operator */

module "kaito" {
  source                                  = "./modules/kaito"
  resource_group_id                       = azurerm_resource_group.rg.id
  resource_group_name                     = azurerm_resource_group.rg.name
  tenant_id                               = data.azurerm_client_config.current.tenant_id
  kaito_aks_namespace                     = var.kaito_aks_namespace
  aks_id                                  = module.aks.id
  aks_node_resource_group_name            = data.azurerm_resource_group.node_resource_group.name
  aks_oidc_issuer_url                     = module.aks.oidc_issuer_url
  ask_workload_managed_identity_id        = module.aks.aks_workload_managed_identity_id
  ask_workload_managed_identity_client_id = module.aks.aks_workload_managed_identity_client_id
  kaito_identity_name                     = local.kaito_identity_name
  kaito_instance_type_vm_size             = var.kaito_instance_type_vm_size
  kaito_service_account_name              = var.kaito_service_account_name
  dns_zone_name                           = var.aks_dns_zone_name

  depends_on = [
    module.aks
  ]
}
