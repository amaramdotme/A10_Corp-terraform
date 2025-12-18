# ============================================================
# Workloads Module - Provider Configuration
# ============================================================
# This module requires three aliased providers to be passed from root

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
      configuration_aliases = [
        azurerm.hq,
        azurerm.sales,
        azurerm.service,
      ]
    }
  }
}
