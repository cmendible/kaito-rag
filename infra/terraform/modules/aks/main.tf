data "azurerm_user_assigned_identity" "user_assigned_identity" {
  name                = var.msi_name
  resource_group_name = var.msi_resource_group_name != null ? var.msi_resource_group_name : var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.name
  sku_tier            = var.sku
  dns_prefix          = var.dns_prefix == null ? "dns-${var.name}" : var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = var.use_node_resource_group ? "${var.resource_group_name}-nodes" : null

  # Enable worload identity and OpenID Connect issuer to (eventually) enable identity federation 
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Enable application routing add-on, as a managed NGINX ingress controller.
  http_application_routing_enabled = true

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
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin = "azure"
  }

  default_node_pool {
    name                        = "system"
    temporary_name_for_rotation = "systemtemp"
    node_count                  = var.system_node_pool_node_count
    vm_size                     = var.system_node_pool_vm_size
    vnet_subnet_id              = var.system_node_pool_vnet_subnet_id
    orchestrator_version        = var.kubernetes_version
    tags                        = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.user_assigned_identity.id]
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = var.msi_auth_for_monitoring_enabled
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool.0.node_count,
      default_node_pool.0.orchestrator_version,
      default_node_pool.0.upgrade_settings,
      default_node_pool.0.tags,
      tags,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_node_pool" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = var.user_node_pool_name
  orchestrator_version  = var.kubernetes_version
  vm_size               = var.user_node_pool_vm_size
  mode                  = "User"
  node_count            = var.user_node_pool_node_count
  vnet_subnet_id        = var.user_node_pool_vnet_subnet_id
  tags                  = var.tags
  node_taints           = var.user_node_pool_node_taints
  node_labels           = var.user_node_pool_node_labels
  enable_auto_scaling   = var.user_node_pool_enable_auto_scaling

  lifecycle {
    ignore_changes = [
      orchestrator_version,
      node_count,
      node_labels,
      node_taints,
      orchestrator_version,
      tags
    ]
  }
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                            = var.resource_group_id
  role_definition_name             = "Network Contributor"
  principal_id                     = data.azurerm_user_assigned_identity.user_assigned_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_monitor_diagnostic_setting" "_" {
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

resource "azurerm_role_assignment" "rbac_cluster_admin_assignment" {
  for_each = toset(var.admin_group_object_ids)

  scope                            = azurerm_kubernetes_cluster.aks.id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id                     = each.key
  skip_service_principal_aad_check = true
  principal_type                   = "User"
}
