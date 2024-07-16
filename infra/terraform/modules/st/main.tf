resource "azurerm_storage_account" "sa" {
  resource_group_name             = var.resource_group_name
  location                        = var.location
  name                            = var.name
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "content" {
  name                  = "content"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}
