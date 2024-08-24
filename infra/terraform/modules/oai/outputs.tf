output "embedding_deployment_name" {
  description = "The name of the embedding deployment."
  value       = azurerm_cognitive_deployment.embedding.name
}

output "endpoint" {
  description = "The endpoint of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.endpoint
  sensitive   = true
}

output "key" {
  description = "The primary access key of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}
