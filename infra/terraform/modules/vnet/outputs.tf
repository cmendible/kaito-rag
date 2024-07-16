output "id" {
  description = "Specifies the resource ID of the Azure Virtual Network."
  value       = azurerm_virtual_network.vnet.id
}

output "name" {
  description = "Specifies the name of the Azure Virtual Network."
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Contains a list of the resource IDs of the subnets"
  value       = { for subnet in azurerm_subnet.subnet : subnet.name => subnet.id }
}

output "subnet_names" {
  description = "Contains a list of the names of the subnets."
  value       = [for subnet in azurerm_subnet.subnet : subnet.name]
}

output "subnet_ids_as_list" {
  description = "Returns the list of the subnet IDs as a list of strings."
  value       = [for subnet in azurerm_subnet.subnet : subnet.id]
}
