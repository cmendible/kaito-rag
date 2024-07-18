output "id" {
  description = "Specifies the resource ID of the Key Vault."
  value       = azurerm_key_vault.kv.id
}

output "vault_uri" {
  description = "Specifies the URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.kv.vault_uri
}
