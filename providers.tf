terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Default provider - uses Azure CLI authentication (az login) or GitHub Actions OIDC
# Authenticates to sub-root subscription by default (where Key Vault lives)
# subscription_id/tenant_id NOT set here to avoid circular dependency with Key Vault data sources
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# Provider for HQ subscription - uses Key Vault secret
provider "azurerm" {
  alias = "hq"
  features {}
  subscription_id                 = local.hq_subscription_id # Fetched from Key Vault
  resource_provider_registrations = "none"
}

# Provider for Sales subscription - uses Key Vault secret
provider "azurerm" {
  alias = "sales"
  features {}
  subscription_id                 = local.sales_subscription_id # Fetched from Key Vault
  resource_provider_registrations = "none"
}

# Provider for Service subscription - uses Key Vault secret
provider "azurerm" {
  alias = "service"
  features {}
  subscription_id                 = local.service_subscription_id # Fetched from Key Vault
  resource_provider_registrations = "none"
}
