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

  # Pass infrastructure constants from input variables
  root_resource_group_name  = var.root_resource_group_name
  root_key_vault_name       = var.root_key_vault_name
  root_storage_account_name = var.root_storage_account_name
}

# ============================================================
# Workloads Module - Resource Groups
# ============================================================
# Creates environment-specific resource groups for each workload

# Fetch current client config for the root subscription (default provider)
data "azurerm_client_config" "current" {}

locals {
  # Construct the Global ACR ID manually to avoid "Chicken and Egg" plan failures.
  # Using a 'data' source would cause 'terraform plan' to fail if the ACR hasn't been created yet.
  # ID Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{name}
  acr_name = module.common.naming_patterns["azurerm_container_registry"]["sales"]
  acr_id   = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${module.common.root_resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${local.acr_name}"
}

module "workloads" {
  source = "../modules/workloads"

  # Pass naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Pass configuration from common module
  location    = module.common.location
  common_tags = module.common.common_tags

  # Networking and ACR
  vnet_address_space    = var.vnet_address_space
  subnet_aks_prefix     = var.subnet_aks_prefix
  subnet_ingress_prefix = var.subnet_ingress_prefix
  acr_id                = local.acr_id

  # Pass aliased providers to the module
  providers = {
    azurerm.hq      = azurerm.hq
    azurerm.sales   = azurerm.sales
    azurerm.service = azurerm.service
  }
}
