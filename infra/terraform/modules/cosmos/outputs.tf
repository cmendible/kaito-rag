output "endpoint" {
  description = "The endpoint of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.db.endpoint
}

output "key" {
  description = "The primary key of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.db.primary_key
  sensitive   = true
}
