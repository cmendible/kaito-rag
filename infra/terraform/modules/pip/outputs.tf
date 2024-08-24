output "public_ip_address" {
  description = "The public IP address of the Azure Public IP resource."
  value       = azurerm_public_ip.public_ip.ip_address
  sensitive   = true
}
