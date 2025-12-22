# ============================================================
# Foundation Root Module
# Deploys organizational structure (Management Groups + Subscriptions)
# This is deployed ONCE per tenant (no environment variants)
# ============================================================

# Call common module for naming patterns
module "common" {
  source = "../modules/common"

  # Foundation doesn't use environment in naming (MGs are global)
  environment = ""
  org_name    = var.org_name
  location    = var.location
  common_tags = var.common_tags

  # Pass infrastructure constants
  root_resource_group_name  = var.root_resource_group_name
  root_key_vault_name       = var.root_key_vault_name
  root_storage_account_name = var.root_storage_account_name
}

# Call foundation module for management groups and subscription associations
module "foundation" {
  source = "../modules/foundation"

  # Pass naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Pass subscription IDs from common module (fetched from Key Vault)
  tenant_id               = module.common.tenant_id
  hq_subscription_id      = module.common.hq_subscription_id
  sales_subscription_id   = module.common.sales_subscription_id
  service_subscription_id = module.common.service_subscription_id

  # Pass tags
  common_tags = module.common.common_tags
}

# Call policies module for governance (Tagging, Locations)
module "policies" {
  source = "../modules/policies"

  management_group_id = module.foundation.management_group_hq_id
  allowed_locations   = var.allowed_locations
}
