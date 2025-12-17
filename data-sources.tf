# Azure Data Sources
# Fetches sensitive configuration from Azure at runtime
# See DECISIONS.md Decision 14 for rationale

# Get current Azure client configuration (authenticated context)
# This provides tenant_id and subscription_id from the authenticated session
# Uses ARM_SUBSCRIPTION_ID and ARM_TENANT_ID environment variables
data "azurerm_client_config" "current" {}

# Reference to the Key Vault
data "azurerm_key_vault" "terraform" {
  name                = "kv-root-terraform"
  resource_group_name = "rg-root-iac"
}

# HQ Subscription ID (fetched from Key Vault)
data "azurerm_key_vault_secret" "hq_subscription_id" {
  name         = "terraform-${var.environment}-hq-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Sales Subscription ID (fetched from Key Vault)
data "azurerm_key_vault_secret" "sales_subscription_id" {
  name         = "terraform-${var.environment}-sales-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Service Subscription ID (fetched from Key Vault)
data "azurerm_key_vault_secret" "service_subscription_id" {
  name         = "terraform-${var.environment}-service-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Locals for convenient access to values
# These are used in providers.tf and other resource files
locals {
  # From authenticated context (no Key Vault needed)
  tenant_id            = data.azurerm_client_config.current.tenant_id
  root_subscription_id = data.azurerm_client_config.current.subscription_id # sub-root

  # From Key Vault (only subscriptions actually used in resources)
  hq_subscription_id      = data.azurerm_key_vault_secret.hq_subscription_id.value
  sales_subscription_id   = data.azurerm_key_vault_secret.sales_subscription_id.value
  service_subscription_id = data.azurerm_key_vault_secret.service_subscription_id.value
}
