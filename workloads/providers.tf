# ============================================================
# Workloads Providers Configuration
# ============================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ============================================================
# Default Provider (sub-root)
# ============================================================
# Uses ARM_SUBSCRIPTION_ID from environment or OIDC authentication
# This provider accesses Key Vault in sub-root subscription

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# ============================================================
# Aliased Providers for Workload Subscriptions
# ============================================================
# These providers use subscription IDs fetched from Key Vault
# via the common module

provider "azurerm" {
  alias           = "hq"
  subscription_id = module.common.hq_subscription_id
  features {}
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias           = "sales"
  subscription_id = module.common.sales_subscription_id
  features {}
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias           = "service"
  subscription_id = module.common.service_subscription_id
  features {}
  resource_provider_registrations = "none"
}
