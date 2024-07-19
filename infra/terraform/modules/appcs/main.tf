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

  #   encryption {
  #     key_vault_key_identifier = var.key_vault_id
  #     identity_client_id       = var.principal_id
  #   }
}
