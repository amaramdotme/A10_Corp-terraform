# ============================================================
# Common Module - Data Sources
# Fetches sensitive configuration from Azure Key Vault at runtime
# See DECISIONS.md Decision 14 for rationale
# ============================================================

# Get current Azure client configuration (authenticated context)
# Provides tenant_id from the authenticated session
# Uses ARM_TENANT_ID environment variable (set via .env or OIDC)
data "azurerm_client_config" "current" {}

# Reference to the Key Vault
# Contains all environment-specific subscription IDs
data "azurerm_key_vault" "terraform" {
  name                = var.root_key_vault_name
  resource_group_name = var.root_resource_group_name
}

# Reference to the Storage Account
# Used for plan uploads and state management
data "azurerm_storage_account" "terraform" {
  name                = var.root_storage_account_name
  resource_group_name = var.root_resource_group_name
}

# Fetch subscription IDs from Key Vault based on environment
# If environment is empty (foundation), defaults to dev subscriptions

# HQ Subscription ID
data "azurerm_key_vault_secret" "hq_subscription_id" {
  name         = var.environment == "" ? "terraform-dev-hq-sub-id" : "terraform-${var.environment}-hq-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Sales Subscription ID
data "azurerm_key_vault_secret" "sales_subscription_id" {
  name         = var.environment == "" ? "terraform-dev-sales-sub-id" : "terraform-${var.environment}-sales-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Service Subscription ID
data "azurerm_key_vault_secret" "service_subscription_id" {
  name         = var.environment == "" ? "terraform-dev-service-sub-id" : "terraform-${var.environment}-service-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}
