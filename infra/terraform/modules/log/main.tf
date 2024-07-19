resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
  retention_in_days   = var.retention_in_days

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
