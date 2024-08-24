resource "azurerm_cognitive_account" "openai" {
  resource_group_name           = var.resource_group_name
  location                      = var.location
  name                          = var.name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  public_network_access_enabled = true
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.Default"

  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type     = "Standard"
    capacity = 65
  }
}
