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
