resource "azurerm_app_configuration" "appcs" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  sku                        = var.sku
  local_auth_enabled         = var.local_authentication_enabled
  public_network_access      = var.public_network_access
  purge_protection_enabled   = false
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.appcs.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_app_configuration_key" "secrets" {
  for_each = { for secret in var.secrets : secret.key => secret.reference }

  configuration_store_id = azurerm_app_configuration.appcs.id
  key                    = each.key
  type                   = "vault"
  vault_key_reference    = each.value

  depends_on = [azurerm_role_assignment.appconf_dataowner]
}

resource "azurerm_app_configuration_key" "values" {
  for_each = { for value in var.values : value.key => value }

  configuration_store_id = azurerm_app_configuration.appcs.id
  content_type           = each.value.content_type
  key                    = each.key
  label                  = each.value.label
  type                   = "kv"
  value                  = each.value.value

  depends_on = [azurerm_role_assignment.appconf_dataowner]
}
