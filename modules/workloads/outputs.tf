# ============================================================
# Workloads Module Outputs
# Expose resource group information for reference
# ============================================================

output "resource_group_shared_id" {
  description = "ID of the shared/common resource group"
  value       = azurerm_resource_group.shared_common.id
}

output "resource_group_shared_name" {
  description = "Name of the shared/common resource group"
  value       = azurerm_resource_group.shared_common.name
}

output "resource_group_sales_id" {
  description = "ID of the sales resource group"
  value       = azurerm_resource_group.sales.id
}

output "resource_group_sales_name" {
  description = "Name of the sales resource group"
  value       = azurerm_resource_group.sales.name
}

output "resource_group_service_id" {
  description = "ID of the service resource group"
  value       = azurerm_resource_group.service.id
}

output "resource_group_service_name" {
  description = "Name of the service resource group"
  value       = azurerm_resource_group.service.name
}

output "resource_groups" {
  description = "Map of all resource group names and resource IDs"
  value = {
    shared = {
      id   = azurerm_resource_group.shared_common.id
      name = azurerm_resource_group.shared_common.name
    }
    sales = {
      id   = azurerm_resource_group.sales.id
      name = azurerm_resource_group.sales.name
    }
    service = {
      id   = azurerm_resource_group.service.id
      name = azurerm_resource_group.service.name
    }
  }
}
