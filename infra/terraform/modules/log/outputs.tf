output "id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  description = "Specifies the resource ID of the Log Analytics Workspace."
}

output "workspace_id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
  description = "Specifies the workspace id of the Log Analytics Workspace."
}

output "primary_shared_key" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
  description = "Specifies the workspace key of the Log Analytics Workspace."
  sensitive   = true
}
