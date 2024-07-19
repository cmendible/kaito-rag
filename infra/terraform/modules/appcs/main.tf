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
    type         = var.identity_type
    identity_ids = var.identity_ids
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.appcs.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}