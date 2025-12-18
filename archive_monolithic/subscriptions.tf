# Note: This configuration assumes subscriptions already exist
# If you need to CREATE new subscriptions, you'll need additional providers and billing account info
# Subscription IDs are fetched from Azure Key Vault

# Associate HQ subscription to mg-a10corp root management group
resource "azurerm_management_group_subscription_association" "hq" {
  management_group_id = azurerm_management_group.a10corp.id
  subscription_id     = "/subscriptions/${local.hq_subscription_id}"
}

# Associate Sales subscription to mg-a10corp-sales management group
resource "azurerm_management_group_subscription_association" "sales" {
  management_group_id = azurerm_management_group.sales.id
  subscription_id     = "/subscriptions/${local.sales_subscription_id}"
}

# Associate Service subscription to mg-a10corp-service
resource "azurerm_management_group_subscription_association" "service" {
  management_group_id = azurerm_management_group.service.id
  subscription_id     = "/subscriptions/${local.service_subscription_id}"
}
