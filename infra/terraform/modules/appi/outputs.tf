output "appi_id" {
  description = "Specifies the resource ID of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.id
}

output "appi_aap_id" {
  description = "Specifies the application ID of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.app_id
}

output "appi_instrumentation_key" {
  description = "Specifies the instrumentation key of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "appi_connection_string" {
  description = "Specifies the connection string of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}
