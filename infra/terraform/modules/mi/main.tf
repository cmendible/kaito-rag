resource "azurerm_user_assigned_identity" "mi" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.name
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
