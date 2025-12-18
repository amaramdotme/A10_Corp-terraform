# ============================================================
# Workloads Root Caller
# ============================================================
# This is the root module for environment-specific workload resources.
# Run terraform commands from this directory:
#   terraform init
#   terraform plan -var-file="environments/dev.tfvars"
#   terraform apply -var-file="environments/dev.tfvars"
#
# The environment variable comes from .tfvars files.
# No variables.tf needed - uses all defaults from common module.

# ============================================================
# Common Module - THE BRAIN
# ============================================================
# Provides: naming patterns, Key Vault data, subscription IDs, tags

module "common" {
  source = "../modules/common"

  # Environment comes from .tfvars file (via -var-file switch)
  environment = var.environment
}

# ============================================================
# Workloads Module - Resource Groups
# ============================================================
# Creates environment-specific resource groups for each workload

module "workloads" {
  source = "../modules/workloads"

  # Pass naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Pass configuration from common module
  location    = module.common.location
  common_tags = module.common.common_tags

  # Pass aliased providers to the module
  providers = {
    azurerm.hq      = azurerm.hq
    azurerm.sales   = azurerm.sales
    azurerm.service = azurerm.service
  }
}
