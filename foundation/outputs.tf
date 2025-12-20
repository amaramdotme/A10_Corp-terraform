# ============================================================
# Foundation Root Module Outputs
# Expose management group information
# ============================================================

output "management_groups" {
  description = "Management group IDs and names"
  value = {
    hq = {
      id   = module.foundation.management_group_hq_id
      name = module.foundation.management_group_hq_name
    }
    sales = {
      id   = module.foundation.management_group_sales_id
      name = module.foundation.management_group_sales_name
    }
    service = {
      id   = module.foundation.management_group_service_id
      name = module.foundation.management_group_service_name
    }
  }
}

output "subscription_associations" {
  description = "Subscription to management group associations"
  value       = module.foundation.subscription_associations
}

output "acr_id" {
  description = "Resource ID of the global ACR"
  value       = azurerm_container_registry.shared.id
}

output "acr_name" {
  description = "Name of the global ACR"
  value       = azurerm_container_registry.shared.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the centralized Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.central.id
}

output "log_analytics_workspace_name" {
  description = "Name of the centralized Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.central.name
}

output "policy_assignments" {
  description = "IDs of the Policy Assignments"
  value       = module.policies.assignment_ids
}
