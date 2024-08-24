output "subnet_id" {
  description = "Specifies the resource ID of the Azure Subnet."
  value       = azurerm_subnet.subnet.id
}

output "nsg_name" {
  description = "Specifies the name of the Azure Network Security Group (NSG)."
  value       = azurerm_network_security_group.nsg.name
}
