output "key" {
  description = "The Primary Key used for the Azure AI Search service."
  value       = azurerm_search_service.search.primary_key
  sensitive   = true
}
