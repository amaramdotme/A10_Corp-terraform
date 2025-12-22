# ============================================================
# Foundation - Global Storage for Application Backups
# Permanent artifact for storing application JSON submissions
# ============================================================

# Use the 'sales' workload name for the storage account
# Since foundation has no environment, naming results in: sta10corpsales
resource "azurerm_storage_account" "backups" {
  name                     = module.common.naming_patterns["azurerm_storage_account"]["sales"]
  resource_group_name      = data.azurerm_resource_group.root.name
  location                 = data.azurerm_resource_group.root.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Requirements imply durability/long-term

  # Requirement: Must allow "Azure Services" to bypass firewall
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = merge(
    module.common.common_tags,
    {
      Workload = "Sales"
      Purpose  = "Application Backups"
    }
  )
}

# Requirement: Containers for dev, stage, prod
resource "azurerm_storage_container" "backups" {
  for_each              = toset(["dev", "stage", "prod"])
  name                  = "backups-${each.key}"
  storage_account_name  = azurerm_storage_account.backups.name
  container_access_type = "private"
}
