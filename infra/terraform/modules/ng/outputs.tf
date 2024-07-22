output "id" {
  description = "Specifies the resource ID of the Azure NAT Gateway."
  value       = azurerm_nat_gateway.nat_gateway.id
}

output "public_ip_address" {
  description = "Contains the public IP address of the Azure NAT Gateway."
  value       = azurerm_public_ip.nat_gategay_public_ip.ip_address
}
