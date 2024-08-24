output "id" {
  description = "Specifies the resource ID of the Key Vault."
  value       = azurerm_key_vault.kv.id
}

output "vault_uri" {
  description = "Specifies the URI of the Key Vault, used for performing operations on keys and secrets."
  value       = azurerm_key_vault.kv.vault_uri
}

output "secrets" {
  # Azure Key Vault secrets do not allow underscores in their names.
  # Use a double hyphen instead and replace it with an underscore in the output.
  description = "Specifies a list of secrets stored in the Key Vault."
  value = [
    for s in azurerm_key_vault_secret.secrets :
    {
      key       = replace(s.name, "--", "_")
      reference = s.versionless_id
    }
  ]
  sensitive = true
}
