# ============================================================
# Common Module Outputs
# Expose naming patterns and variables to parent modules
# ============================================================

output "naming_patterns" {
  description = "Map of resource types to workload-specific names following CAF standards"
  value       = local.naming_patterns

  # Example structure:
  # {
  #   "azurerm_resource_group" = {
  #     "hq"      = "rg-a10corp-hq-dev"
  #     "shared"  = "rg-a10corp-shared-dev"
  #     "sales"   = "rg-a10corp-sales-dev"
  #     "service" = "rg-a10corp-service-dev"
  #   }
  #   "azurerm_management_group" = {
  #     "hq"      = "mg-a10corp-hq"
  #     "sales"   = "mg-a10corp-sales"
  #     "service" = "mg-a10corp-service"
  #   }
  # }
}

output "org_name" {
  description = "Organization name used in naming patterns"
  value       = var.org_name
}

output "environment" {
  description = "Environment name (dev, stage, prod)"
  value       = var.environment
}

output "location" {
  description = "Azure region for resource deployment"
  value       = var.location
}

output "common_tags" {
  description = "Common tags to apply to resources"
  value       = var.common_tags
}

output "workloads" {
  description = "List of all workload identifiers"
  value       = local.workloads
}

# ============================================================
# Subscription IDs from Key Vault
# ============================================================

output "tenant_id" {
  description = "Azure Tenant ID from authenticated session"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}

output "hq_subscription_id" {
  description = "HQ subscription ID from Key Vault"
  value       = data.azurerm_key_vault_secret.hq_subscription_id.value
  sensitive   = true
}

output "sales_subscription_id" {
  description = "Sales subscription ID from Key Vault"
  value       = data.azurerm_key_vault_secret.sales_subscription_id.value
  sensitive   = true
}

output "service_subscription_id" {
  description = "Service subscription ID from Key Vault"
  value       = data.azurerm_key_vault_secret.service_subscription_id.value
  sensitive   = true
}
