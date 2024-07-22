output "id" {
  description = "Specifies the resource ID of the Azure Container Registry (ACR)."
  value       = azurerm_container_registry.acr.id
}

output "name" {
  description = "Specifies the name of the Azure Container Registry (ACR)."
  value       = azurerm_container_registry.acr.name
}

output "location" {
  value       = azurerm_container_registry.acr.location
  description = "Specifies the location of the Azure Container Registry (ACR)."
}

output "login_server" {
  description = "Specifies the login server of the Azure Container Registry (ACR)."
  value       = azurerm_container_registry.acr.login_server
}

output "login_server_url" {
  description = "Specifies the login server url of the Azure Container Registry (ACR)."
  value       = "https://${azurerm_container_registry.acr.login_server}"
}

output "admin_username" {
  description = "Specifies the admin username of the Azure Container Registry (ACR)."
  value       = azurerm_container_registry.acr.admin_username
}
