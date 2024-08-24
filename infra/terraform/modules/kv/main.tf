data "azurerm_client_config" "current" {}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault" "kv" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = lower(var.sku)
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = false
  tags                       = var.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_key_vault_access_policy" "main_principal" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = var.principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "current_user_principal" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = data.azuread_user.current_user.object_id

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]
}

resource "azurerm_key_vault_secret" "secrets" {
  # Create a map for each secret in `var.secrets` where the key is the secret name and the value is the secret value.
  # Azure Key Vault secrets do not allow underscores in their names. Use a double hyphen instead.
  for_each = { for secret in var.secrets : replace(secret.name, "_", "--") => secret.value }

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.main_principal,
    azurerm_key_vault_access_policy.current_user_principal
  ]
}
