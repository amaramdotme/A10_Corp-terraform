# ============================================================
# Management Groups
# ============================================================

# A10 Corporation Root Management Group
# Parent is Tenant Root Group - using tenant_id from Key Vault
resource "azurerm_management_group" "a10corp" {
  display_name               = local.naming_patterns["azurerm_management_group"]["hq"]
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${local.tenant_id}"
}

# Sales Business Unit Management Group
resource "azurerm_management_group" "sales" {
  display_name               = local.naming_patterns["azurerm_management_group"]["sales"]
  parent_management_group_id = azurerm_management_group.a10corp.id
}

# Service Business Unit Management Group
resource "azurerm_management_group" "service" {
  display_name               = local.naming_patterns["azurerm_management_group"]["service"]
  parent_management_group_id = azurerm_management_group.a10corp.id
}
