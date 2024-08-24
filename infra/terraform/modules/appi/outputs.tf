output "id" {
  description = "Specifies the resource ID of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.id
}

output "aap_id" {
  description = "Specifies the application ID of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.app_id
}

output "instrumentation_key" {
  description = "Specifies the instrumentation key of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Specifies the connection string of the Azure Application Insights."
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}
