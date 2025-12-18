# ============================================================
# Workloads Module - Resource Groups
# Environment-specific resource groups (can be destroyed and recreated safely)
# ============================================================

# Shared/Common Resource Group
# Deployed to HQ subscription
resource "azurerm_resource_group" "shared_common" {
  name     = var.naming_patterns["azurerm_resource_group"]["shared"]
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Shared"
      Purpose  = "Common resources across A10 Corp"
    }
  )
}

# Sales Resource Group
# Deployed to Sales subscription
resource "azurerm_resource_group" "sales" {
  name     = var.naming_patterns["azurerm_resource_group"]["sales"]
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Sales"
    }
  )
}

# Service Resource Group
# Deployed to Service subscription
resource "azurerm_resource_group" "service" {
  name     = var.naming_patterns["azurerm_resource_group"]["service"]
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Service"
    }
  )
}
