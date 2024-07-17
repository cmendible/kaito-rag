resource "azurerm_storage_account" "sa" {
  resource_group_name             = var.resource_group_name
  location                        = var.location
  name                            = var.name
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "user_content" {
  name                  = "user-documents"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}

resource "azurerm_storage_container" "global_content" {
  name                  = "global-documents"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}

resource "azurerm_storage_blob" "docs" {
  for_each               = fileset("${path.module}/docs", "*")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.global_content.name
  type                   = "Block"
  source                 = "${path.module}/docs/${each.value}"
  content_md5            = filemd5("${path.module}/docs/${each.value}")
}
