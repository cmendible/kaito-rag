output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the resource group"
}

output "aks_cluster_name" {
  value       = module.aks.name
  description = "The name of the Azure Kubernetes Service (AKS) cluster"
}

output "appcs_primary_read_connection_string" {
  description = "The primary read connection string to the Azure App Configuration"
  value       = module.appcs.primary_read_key_connection_string
}
