# ============================================================
# Management Group Outputs
# ============================================================

output "management_group_a10corp_id" {
  description = "The ID of the A10 Corp root management group (mg-a10corp-hq)"
  value       = azurerm_management_group.a10corp.id
}

output "management_group_a10corp_name" {
  description = "The display name of the A10 Corp root management group"
  value       = azurerm_management_group.a10corp.display_name
}

output "management_group_sales_id" {
  description = "The ID of the Sales management group (mg-a10corp-sales)"
  value       = azurerm_management_group.sales.id
}

output "management_group_sales_name" {
  description = "The display name of the Sales management group"
  value       = azurerm_management_group.sales.display_name
}

output "management_group_service_id" {
  description = "The ID of the Service management group (mg-a10corp-service)"
  value       = azurerm_management_group.service.id
}

output "management_group_service_name" {
  description = "The display name of the Service management group"
  value       = azurerm_management_group.service.display_name
}

# ============================================================
# Resource Group Outputs
# ============================================================

output "resource_group_shared_name" {
  description = "The name of the shared/common resource group"
  value       = azurerm_resource_group.shared_common.name
}

output "resource_group_shared_id" {
  description = "The ID of the shared/common resource group"
  value       = azurerm_resource_group.shared_common.id
}

output "resource_group_shared_location" {
  description = "The location of the shared/common resource group"
  value       = azurerm_resource_group.shared_common.location
}

output "resource_group_sales_name" {
  description = "The name of the sales resource group"
  value       = azurerm_resource_group.sales.name
}

output "resource_group_sales_id" {
  description = "The ID of the sales resource group"
  value       = azurerm_resource_group.sales.id
}

output "resource_group_sales_location" {
  description = "The location of the sales resource group"
  value       = azurerm_resource_group.sales.location
}

output "resource_group_service_name" {
  description = "The name of the service resource group"
  value       = azurerm_resource_group.service.name
}

output "resource_group_service_id" {
  description = "The ID of the service resource group"
  value       = azurerm_resource_group.service.id
}

output "resource_group_service_location" {
  description = "The location of the service resource group"
  value       = azurerm_resource_group.service.location
}

# ============================================================
# Subscription Association Outputs
# ============================================================

output "subscription_association_hq" {
  description = "HQ subscription associated with mg-a10corp-hq"
  value = {
    subscription_id     = local.hq_subscription_id
    management_group_id = azurerm_management_group.a10corp.id
  }
  sensitive = true # Subscription ID is sensitive
}

output "subscription_association_sales" {
  description = "Sales subscription associated with mg-a10corp-sales"
  value = {
    subscription_id     = local.sales_subscription_id
    management_group_id = azurerm_management_group.sales.id
  }
  sensitive = true # Subscription ID is sensitive
}

output "subscription_association_service" {
  description = "Service subscription associated with mg-a10corp-service"
  value = {
    subscription_id     = local.service_subscription_id
    management_group_id = azurerm_management_group.service.id
  }
  sensitive = true # Subscription ID is sensitive
}

# ============================================================
# Summary Output
# ============================================================

output "infrastructure_summary" {
  description = "Complete summary of deployed infrastructure"
  value = {
    environment = var.environment
    location    = var.location
    management_groups = {
      a10corp = {
        id           = azurerm_management_group.a10corp.id
        display_name = azurerm_management_group.a10corp.display_name
      }
      sales = {
        id           = azurerm_management_group.sales.id
        display_name = azurerm_management_group.sales.display_name
      }
      service = {
        id           = azurerm_management_group.service.id
        display_name = azurerm_management_group.service.display_name
      }
    }
    resource_groups = {
      shared = {
        name     = azurerm_resource_group.shared_common.name
        id       = azurerm_resource_group.shared_common.id
        location = azurerm_resource_group.shared_common.location
      }
      sales = {
        name     = azurerm_resource_group.sales.name
        id       = azurerm_resource_group.sales.id
        location = azurerm_resource_group.sales.location
      }
      service = {
        name     = azurerm_resource_group.service.name
        id       = azurerm_resource_group.service.id
        location = azurerm_resource_group.service.location
      }
    }
  }
}
