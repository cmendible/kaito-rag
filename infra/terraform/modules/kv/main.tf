resource "azurerm_key_vault" "kv" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = lower(var.sku)
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = false
  tags                       = var.tags

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.principal_id

    secret_permissions = [
      "Get",
    ]
  }
}
