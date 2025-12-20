# ============================================================
# Foundation - Global Container Registry
# Permanent artifact for storing Docker images
# ============================================================

# Reference existing pre-Terraform resource group (rg-root-iac)
# This RG contains Key Vault and Storage, so it's the perfect place for shared artifacts
data "azurerm_resource_group" "root" {
  name = module.common.root_resource_group_name
}

# Azure Container Registry
# Pattern: acr{org}{workload} (e.g., acra10corpsales)
resource "azurerm_container_registry" "shared" {
  name                = module.common.naming_patterns["azurerm_container_registry"]["sales"]
  resource_group_name = data.azurerm_resource_group.root.name
  location            = data.azurerm_resource_group.root.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = merge(
    module.common.common_tags,
    {
      Workload = "Shared"
      Purpose  = "Global Artifact Repository"
    }
  )
}