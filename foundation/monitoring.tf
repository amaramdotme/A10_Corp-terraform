# ============================================================
# Foundation - Global Monitoring
# Centralized Log Analytics Workspace for persistent forensics
# ============================================================

# The Workspace is deployed in the root management subscription
# It outlives all workload-specific environments (dev, stage, prod)
resource "azurerm_log_analytics_workspace" "central" {
  name                = module.common.naming_patterns["azurerm_log_analytics_workspace"]["hq"]
  resource_group_name = data.azurerm_resource_group.root.name
  location            = data.azurerm_resource_group.root.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    module.common.common_tags,
    {
      Workload = "Shared"
      Purpose  = "Centralized Forensics & Audit Logs"
    }
  )
}
