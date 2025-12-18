# ============================================================
# Foundation Module - Subscription Associations
# Associates subscriptions to their respective management groups
# ============================================================

# Note: This configuration assumes subscriptions already exist
# Subscription IDs are passed from the parent module as variables
# The parent module fetches these IDs from Azure Key Vault via data sources

# Associate HQ subscription to mg-a10corp root management group
resource "azurerm_management_group_subscription_association" "hq" {
  management_group_id = azurerm_management_group.a10corp.id
  subscription_id     = "/subscriptions/${var.hq_subscription_id}"
}

# Associate Sales subscription to mg-a10corp-sales management group
resource "azurerm_management_group_subscription_association" "sales" {
  management_group_id = azurerm_management_group.sales.id
  subscription_id     = "/subscriptions/${var.sales_subscription_id}"
}

# Associate Service subscription to mg-a10corp-service management group
resource "azurerm_management_group_subscription_association" "service" {
  management_group_id = azurerm_management_group.service.id
  subscription_id     = "/subscriptions/${var.service_subscription_id}"
}
