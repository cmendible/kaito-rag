output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the resource group"
}

output "aks_cluster_name" {
  value       = module.aks.name
  description = "The name of the Azure Kubernetes Service (AKS) cluster"
}

output "aks_node_resource_group_name" {
  description = "The name of the node Resource Group on the Azure Kubernetes Service (AKS) cluster"
  value       = data.azurerm_resource_group.node_resource_group.name
}

output "appcs_primary_read_connection_string" {
  description = "The primary read connection string to the Azure App Configuration"
  value       = module.appcs.primary_read_key_connection_string
}
