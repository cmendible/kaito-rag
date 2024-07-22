output "id" {
  description = "Specifies the resource ID of the Azure App Configuration."
  value       = azurerm_app_configuration.appcs.id
}

output "primary_read_key_connection_string" {
  description = "Specifies the connection string of the primary read key."
  value       = azurerm_app_configuration.appcs.primary_read_key.0.connection_string
  sensitive   = true
}
