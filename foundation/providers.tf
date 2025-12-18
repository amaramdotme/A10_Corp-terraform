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
# Authenticates to sub-root subscription (where Key Vault lives)
# The common module will fetch subscription IDs from Key Vault using this provider
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
