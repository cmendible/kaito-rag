data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

locals {
  create_bot_app      = var.type == "SingleTenant" || var.type == "MultiTenant"
  is_bot_multi_tenant = var.type == "MultiTenant"
  is_bot_user_msi     = var.type == "UserAssignedMSI"
}

resource "azurerm_user_assigned_identity" "bot_user_assigned_identity" {
  count               = !local.create_bot_app ? 1 : 0
  resource_group_name = var.resource_group_name
  location            = var.user_assigned_identity_location
  name                = "id-${var.name}"
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azuread_application" "bot_app" {
  count            = local.create_bot_app ? 1 : 0
  display_name     = var.name
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = local.is_bot_multi_tenant ? "AzureADandPersonalMicrosoftAccount" : "AzureADMyOrg"

  api {
    requested_access_token_version = local.is_bot_multi_tenant ? 2 : 1
  }
}

resource "time_rotating" "bot_app_secret_time_rotating" {
  count         = local.create_bot_app ? 1 : 0
  rotation_days = 180
}

resource "azuread_application_password" "bot_app_password" {
  count          = local.create_bot_app ? 1 : 0
  application_id = azuread_application.bot_app.0.id
  display_name   = "${var.name}-secret"
  start_date     = time_rotating.bot_app_secret_time_rotating.0.id
  end_date       = timeadd(time_rotating.bot_app_secret_time_rotating.0.id, "4320h")
}

resource "azurerm_application_insights_api_key" "bot_azurerm_application_insights_api_key" {

  name                    = "appinsights-api-key-${var.name}"
  application_insights_id = var.application_insights_id
  read_permissions        = ["aggregate", "api", "draft", "extendqueries", "search"]
  write_permissions       = ["annotations"]
}

resource "azurerm_bot_service_azure_bot" "bot" {
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  location                              = var.location
  microsoft_app_id                      = local.create_bot_app ? azuread_application.bot_app.0.client_id : azurerm_user_assigned_identity.bot_user_assigned_identity.0.client_id
  microsoft_app_type                    = var.type
  microsoft_app_tenant_id               = local.is_bot_multi_tenant ? null : data.azurerm_client_config.current.tenant_id
  microsoft_app_msi_id                  = local.is_bot_user_msi ? azurerm_user_assigned_identity.bot_user_assigned_identity.0.id : null
  sku                                   = var.sku
  developer_app_insights_key            = var.application_insights_instrumentation_key
  developer_app_insights_api_key        = azurerm_application_insights_api_key.bot_azurerm_application_insights_api_key.api_key
  developer_app_insights_application_id = var.application_insights_app_id
  endpoint                              = var.backend_endpoint
  tags                                  = var.tags
}

resource "azurerm_bot_channel_directline" "bot_directline" {
  bot_name            = azurerm_bot_service_azure_bot.bot.name
  location            = azurerm_bot_service_azure_bot.bot.location
  resource_group_name = azurerm_bot_service_azure_bot.bot.resource_group_name

  site {
    name    = "default"
    enabled = true
  }
}

resource "azurerm_bot_channel_ms_teams" "bot_ms_teams" {
  bot_name            = azurerm_bot_service_azure_bot.bot.name
  location            = azurerm_bot_service_azure_bot.bot.location
  resource_group_name = azurerm_bot_service_azure_bot.bot.resource_group_name
}

# resource "azurerm_key_vault_secret" "kv-directline-secret" {
#   name         = "${var.name}-directline-secret"
#   value        = [for s in azurerm_bot_channel_directline.bot_directline.site : s.key][0]
#   key_vault_id = var.key_vault_id
# }

# resource "azurerm_key_vault_secret" "kv-bot-password" {
#   name         = "${var.name}-bot-password"
#   value        = local.create_bot_app ? azuread_application_password.bot_app_password[0].value : ""
#   key_vault_id = var.key_vault_id
# }
