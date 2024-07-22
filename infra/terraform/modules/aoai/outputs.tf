output "openai_service_name" {
  description = "The name of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.name
}

output "embedding_deployment_name" {
  description = "The name of the embedding deployment."
  value       = azurerm_cognitive_deployment.embedding.name
}

output "openai_endpoint" {
  description = "The endpoint of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.endpoint
  sensitive   = true
}

output "openai_key" {
  description = "The primary access key of the Azure OpenAI service."
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}
