# ============================================================
# Workloads Module Outputs
# ============================================================

output "resource_groups" {
  description = "Resource Group names and IDs"
  value = {
    shared = {
      name = azurerm_resource_group.shared_common.name
      id   = azurerm_resource_group.shared_common.id
    }
    sales = {
      name = azurerm_resource_group.sales.name
      id   = azurerm_resource_group.sales.id
    }
    service = {
      name = azurerm_resource_group.service.name
      id   = azurerm_resource_group.service.id
    }
  }
}

output "resource_group_name" {
  description = "Name of the primary Sales resource group"
  value       = azurerm_resource_group.sales.name
}

# ============================================================
# Networking Outputs
# ============================================================

output "vnet_id" {
  description = "ID of the Sales VNet"
  value       = azurerm_virtual_network.sales.id
}

output "subnet_id_aks_nodes" {
  description = "ID of the AKS Nodes subnet"
  value       = azurerm_subnet.aks_nodes.id
}

output "subnet_id_ingress" {
  description = "ID of the Ingress subnet"
  value       = azurerm_subnet.ingress.id
}

# ============================================================
# Identity Outputs
# ============================================================

output "identity_id_aks" {
  description = "Resource ID of the AKS User Assigned Identity"
  value       = azurerm_user_assigned_identity.aks.id
}

output "identity_client_id_aks" {
  description = "Client ID of the AKS User Assigned Identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# ============================================================
# Storage Outputs
# ============================================================

output "storage_account_id" {
  description = "Resource ID of the permanent backup storage account"
  value       = var.storage_account_backups_id
}

output "storage_account_name" {
  description = "Name of the permanent backup storage account"
  value       = var.storage_account_backups_name
}