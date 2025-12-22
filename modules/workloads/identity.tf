# ============================================================
# Workloads Module - Identity
# Managed Identity for AKS and Role Assignments
# ============================================================

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  provider = azurerm.sales

  name                = var.naming_patterns["azurerm_user_assigned_identity"]["sales"]
  resource_group_name = azurerm_resource_group.sales.name
  location            = azurerm_resource_group.sales.location

  tags = merge(
    var.common_tags,
    {
      Workload = "Sales"
      Purpose  = "AKS Control Plane Identity"
    }
  )
}

# Role Assignment: AcrPull on Global ACR
resource "azurerm_role_assignment" "acr_pull" {
  provider = azurerm.root # Assignment scope is the ACR in the ROOT subscription

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Role Assignment: Storage Blob Data Contributor on Backups Storage
resource "azurerm_role_assignment" "storage_contributor" {
  provider = azurerm.root # Assignment scope is the Storage Account in the ROOT subscription

  scope                = var.storage_account_backups_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Role Assignment: Network Contributor on VNet
resource "azurerm_role_assignment" "network_contributor" {
  provider = azurerm.sales

  scope                = azurerm_virtual_network.sales.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
