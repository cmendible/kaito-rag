locals {
  direct_line_urls = {
    global       = "https://directline.botframework.com"
    westeurope   = "https://europe.directline.botframework.com"
    centralindia = "https://india.directline.botframework.com"
  }

  # Based on the location of the Azure Bot, look up for the Direct Line URL. If not found, use the global URL as default.
  bot_url = lookup(local.direct_line_urls, var.location, local.direct_line_urls.global)
}

output "type" {
  description = "The type of this Azure Bot."
  value       = azurerm_bot_service_azure_bot.bot.microsoft_app_type
}

output "app_id" {
  description = "The bot's app ID. If the bot's type is `UserAssignedMSI`, this will be client ID of the user-assigned managed identity."
  value       = azurerm_bot_service_azure_bot.bot.microsoft_app_id
}

output "tenant_id" {
  description = "The bot's app Tenant ID. If the bot's type is `MultiTenant`, this will be an empty string."
  value       = local.is_bot_multi_tenant ? "" : azurerm_bot_service_azure_bot.bot.microsoft_app_tenant_id
}

output "password" {
  description = "The bot's app password. If the bot's type is `UserAssignedMSI`, this will be an empty string."
  value       = local.create_bot_app ? azuread_application_password.bot_app_password.0.value : ""
  sensitive   = true
}

output "direct_line_endpoint" {
  description = "The endpoint of the Direct Line channel."
  value       = local.bot_url
}

output "direct_line_key" {
  description = "The secret key of the Direct Line channel."
  value       = [for s in azurerm_bot_channel_directline.bot_directline.site : s.key][0]
  sensitive   = true
}
