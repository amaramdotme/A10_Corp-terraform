# ============================================================
# Foundation Module - Management Groups
# One-time organizational structure (rarely changed, never destroyed)
# ============================================================

# A10 Corporation Root Management Group
# Parent is Tenant Root Group - using tenant_id from parent module
resource "azurerm_management_group" "a10corp" {
  display_name               = var.naming_patterns["azurerm_management_group"]["hq"]
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

# Sales Business Unit Management Group
resource "azurerm_management_group" "sales" {
  display_name               = var.naming_patterns["azurerm_management_group"]["sales"]
  parent_management_group_id = azurerm_management_group.a10corp.id
}

# Service Business Unit Management Group
resource "azurerm_management_group" "service" {
  display_name               = var.naming_patterns["azurerm_management_group"]["service"]
  parent_management_group_id = azurerm_management_group.a10corp.id
}
