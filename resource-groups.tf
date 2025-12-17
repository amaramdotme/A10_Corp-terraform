# ============================================================
# Resource Groups
# ============================================================

# Shared/Common Resource Group
resource "azurerm_resource_group" "shared_common" {
  provider = azurerm.hq
  name     = local.naming_patterns["azurerm_resource_group"]["shared"]
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
resource "azurerm_resource_group" "sales" {
  provider = azurerm.sales
  name     = local.naming_patterns["azurerm_resource_group"]["sales"]
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Sales"
    }
  )
}

# Service Resource Group
resource "azurerm_resource_group" "service" {
  provider = azurerm.service
  name     = local.naming_patterns["azurerm_resource_group"]["service"]
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Service"
    }
  )
}
