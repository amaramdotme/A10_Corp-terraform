# ============================================================
# Workloads Root Outputs
# ============================================================

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "resource_groups" {
  description = "Map of created resource groups"
  value       = module.workloads.resource_groups
}

output "workload_summary" {
  description = "Summary of workload resources created"
  value = {
    environment     = var.environment
    resource_groups = module.workloads.resource_groups
    naming_patterns = module.common.naming_patterns
  }
}
