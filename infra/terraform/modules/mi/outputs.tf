output "id" {
  description = "The ID of the managed identity."
  value       = azurerm_user_assigned_identity.mi.id
}

output "principal_id" {
  description = "The principal ID of the managed identity."
  value       = azurerm_user_assigned_identity.mi.principal_id
}

output "client_id" {
  description = "The client ID of the managed identity."
  value       = azurerm_user_assigned_identity.mi.client_id
}

output "tenant_id" {
  description = "The client ID of the managed identity."
  value       = azurerm_user_assigned_identity.mi.tenant_id
}

output "name" {
  description = "The name of the managed identity."
  value       = azurerm_user_assigned_identity.mi.name
}

output "resource_group_name" {
  description = "The resource group name of the managed identity."
  value       = azurerm_user_assigned_identity.mi.resource_group_name
}
