output "appi_id" {
  value = azurerm_application_insights.appinsights.id
}

output "appi_aap_id" {
  value = azurerm_application_insights.appinsights.app_id
}

output "appi_instrumentation_key" {
  value = azurerm_application_insights.appinsights.instrumentation_key
}

output "appi_connection_string" {
  value = azurerm_application_insights.appinsights.connection_string
}
