locals {
  network_plugin_mode = var.network_plugin_mode == null ? "" : lower(var.network_plugin_mode)
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  name = "id-${var.name}"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name              = var.resource_group_name
  location                         = var.location
  name                             = var.name
  sku_tier                         = var.sku
  kubernetes_version               = var.kubernetes_version
  dns_prefix                       = var.dns_prefix == null ? "dns-${var.name}" : var.dns_prefix
  private_cluster_enabled          = var.private_cluster_enabled
  automatic_channel_upgrade        = var.automatic_channel_upgrade
  workload_identity_enabled        = var.workload_identity_enabled
  oidc_issuer_enabled              = var.oidc_issuer_enabled
  open_service_mesh_enabled        = var.open_service_mesh_enabled
  image_cleaner_enabled            = var.image_cleaner_enabled
  image_cleaner_interval_hours     = var.image_cleaner_interval_hours
  azure_policy_enabled             = var.azure_policy_enabled
  http_application_routing_enabled = var.http_application_routing_enabled
  tags                             = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = tolist([azurerm_user_assigned_identity.aks_identity.id])
  }

  default_node_pool { # System Node Pool
    name                         = var.system_node_pool_name
    vm_size                      = var.system_node_pool_vm_size
    vnet_subnet_id               = var.system_node_pool_vnet_subnet_id
    pod_subnet_id                = lower(local.network_plugin_mode) != "overlay" ? var.system_node_pool_pod_subnet_id : null
    zones                        = var.system_node_pool_availability_zones
    orchestrator_version         = var.kubernetes_version
    node_labels                  = var.system_node_pool_node_labels
    only_critical_addons_enabled = var.system_node_pool_only_critical_addons_enabled
    enable_auto_scaling          = var.system_node_pool_enable_auto_scaling
    enable_host_encryption       = var.system_node_pool_enable_host_encryption
    enable_node_public_ip        = var.system_node_pool_enable_node_public_ip
    max_pods                     = var.system_node_pool_max_pods
    max_count                    = var.system_node_pool_max_count
    min_count                    = var.system_node_pool_min_count
    node_count                   = var.system_node_pool_node_count
    os_disk_type                 = var.system_node_pool_os_disk_type
    temporary_name_for_rotation  = "temp${var.system_node_pool_name}"
    tags                         = var.tags
  }

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.azure_rbac_enabled
  }

  oms_agent {
    msi_auth_for_monitoring_enabled = var.msi_auth_for_monitoring_enabled
    log_analytics_workspace_id      = var.log_analytics_workspace_id
  }

  dynamic "web_app_routing" {
    for_each = var.web_app_routing.enabled ? [1] : []

    content {
      dns_zone_id = var.web_app_routing.dns_zone_id
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = try(var.ingress_application_gateway.gateway_id, null) == null ? [] : [1]

    content {
      gateway_id  = var.ingress_application_gateway.gateway_id
      subnet_cidr = var.ingress_application_gateway.subnet_cidr
      subnet_id   = var.ingress_application_gateway.subnet_id
    }
  }

  network_profile {
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = var.pod_cidr
    network_plugin      = var.network_plugin
    network_plugin_mode = local.network_plugin_mode == "" ? null : local.network_plugin_mode
    network_mode        = lower(var.network_plugin) == "azure" ? var.network_mode : null
    network_policy      = var.network_policy
    outbound_type       = var.outbound_type
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  workload_autoscaler_profile {
    keda_enabled                    = var.keda_enabled
    vertical_pod_autoscaler_enabled = var.vertical_pod_autoscaler_enabled
  }

  monitor_metrics {
    annotations_allowed = var.annotations_allowed
    labels_allowed      = var.labels_allowed
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      tags,
      default_node_pool.0.tags,
      default_node_pool.0.upgrade_settings,
      default_node_pool.0.node_labels,
      default_node_pool.0.node_count,
      default_node_pool.0.orchestrator_version,
      monitor_metrics,
      azure_policy_enabled,
    ]
  }
}

resource "azurerm_role_assignment" "network_contributor_assignment" {
  scope                            = var.resource_group_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_monitor_diagnostic_setting" "settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  metric {
    category = "AllMetrics"
  }
}

/* User Node Pool */

resource "azurerm_kubernetes_cluster_node_pool" "user_node_pool" {
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks.id
  name                         = var.user_node_pool_name
  vm_size                      = var.user_node_pool_vm_size
  mode                         = "User"
  node_labels                  = var.user_node_pool_node_labels
  node_taints                  = var.user_node_pool_node_taints
  zones                        = var.user_node_pool_availability_zones
  vnet_subnet_id               = var.user_node_pool_vnet_subnet_id
  pod_subnet_id                = var.user_node_pool_pod_subnet_id
  enable_auto_scaling          = var.user_node_pool_enable_auto_scaling
  enable_host_encryption       = var.user_node_pool_enable_host_encryption
  enable_node_public_ip        = var.user_node_pool_enable_node_public_ip
  proximity_placement_group_id = var.user_node_pool_proximity_placement_group_id
  orchestrator_version         = var.kubernetes_version
  max_pods                     = var.user_node_pool_max_pods
  max_count                    = var.user_node_pool_max_count
  min_count                    = var.user_node_pool_min_count
  node_count                   = var.user_node_pool_node_count
  os_disk_size_gb              = var.user_node_pool_os_disk_size_gb
  os_disk_type                 = var.user_node_pool_os_disk_type
  os_type                      = var.user_node_pool_os_type
  priority                     = var.user_node_pool_priority
  tags                         = var.tags

  lifecycle {
    ignore_changes = [
      tags,
      upgrade_settings,
      node_labels,
      node_count,
      orchestrator_version,
    ]
  }
}

/* Workload */

resource "azurerm_user_assigned_identity" "aks_workload_identity" {
  name                = "id-workload-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

/* AKS RBAC Cluster Admin assigment */

resource "azurerm_role_assignment" "aks_rbac_cluster_admin_assignment" {
  for_each = toset(var.admin_group_object_ids)

  scope                            = azurerm_kubernetes_cluster.aks.id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id                     = each.key
  skip_service_principal_aad_check = true
  principal_type                   = "User"

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}