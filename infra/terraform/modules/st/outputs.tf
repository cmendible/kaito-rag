output "connection_string" {
  value = azurerm_storage_account.sa.primary_connection_string
}

output "key" {
  value = azurerm_storage_account.sa.primary_access_key
}
