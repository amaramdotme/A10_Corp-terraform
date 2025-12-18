# ============================================================
# Foundation Module Outputs
# Expose management group IDs for reference by other modules
# ============================================================

output "management_group_hq_id" {
  description = "ID of the A10 Corp HQ management group"
  value       = azurerm_management_group.a10corp.id
}

output "management_group_hq_name" {
  description = "Display name of the A10 Corp HQ management group"
  value       = azurerm_management_group.a10corp.display_name
}

output "management_group_sales_id" {
  description = "ID of the Sales management group"
  value       = azurerm_management_group.sales.id
}

output "management_group_sales_name" {
  description = "Display name of the Sales management group"
  value       = azurerm_management_group.sales.display_name
}

output "management_group_service_id" {
  description = "ID of the Service management group"
  value       = azurerm_management_group.service.id
}

output "management_group_service_name" {
  description = "Display name of the Service management group"
  value       = azurerm_management_group.service.display_name
}

output "subscription_associations" {
  description = "Map of subscription associations to management groups"
  value = {
    hq      = azurerm_management_group_subscription_association.hq.id
    sales   = azurerm_management_group_subscription_association.sales.id
    service = azurerm_management_group_subscription_association.service.id
  }
}
