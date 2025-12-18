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
