output "mi_id" {
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
