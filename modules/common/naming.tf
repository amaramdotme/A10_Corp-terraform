# ============================================================
# Azure CAF Naming Convention
# This module provides centralized naming logic for all resources
# following Azure Cloud Adoption Framework standards
# ============================================================

locals {
  # Map Azure resource types to their CAF resource type prefixes
  resource_type_map = {
    "azurerm_resource_group"         = "rg"
    "azurerm_management_group"       = "mg"
    "azurerm_virtual_machine"        = "vm"
    "azurerm_policy_group"           = "pg"
    "azurerm_storage_account"        = "st"
    "azurerm_container_registry"     = "acr"
    "azurerm_virtual_network"        = "vnet"
    "azurerm_subnet"                 = "snet"
    "azurerm_user_assigned_identity" = "id"
    "azurerm_log_analytics_workspace" = "log"
    "azurerm_application_insights"    = "appi"
    "azurerm_network_security_group"  = "nsg"
    "azurerm_route_table"             = "route"
  }

  # Global workloads list
  # Note: "hq" is for management groups only, "shared" is for resource groups only
  workloads = ["hq", "shared", "sales", "service"]

  # SINGLE SOURCE OF TRUTH:
  # include_env = true  => {prefix}-{org}-{workload}-{env}
  # include_env = false => {prefix}-{org}-{workload}
  resource_include_env = {
    "azurerm_resource_group"         = true
    "azurerm_virtual_machine"        = true
    "azurerm_management_group"       = false
    "azurerm_policy_group"           = false
    "azurerm_storage_account"        = true
    "azurerm_container_registry"     = false
    "azurerm_virtual_network"        = true
    "azurerm_subnet"                 = true
    "azurerm_user_assigned_identity" = true
    "azurerm_log_analytics_workspace" = false # Global monitoring
    "azurerm_application_insights"    = true  # Apps are env-specific
    "azurerm_network_security_group"  = true
    "azurerm_route_table"             = true
  }

  # Optional validation helpers
  resource_types_defined_in_rules = toset(keys(local.resource_include_env))
  resource_types_defined_in_map   = toset(keys(local.resource_type_map))

  missing_prefix_keys = setsubtract(
    local.resource_types_defined_in_rules,
    local.resource_types_defined_in_map
  )

  unruled_resource_types = setsubtract(
    local.resource_types_defined_in_map,
    local.resource_types_defined_in_rules
  )
}

# ============================================================
# Naming Patterns - Access via local.naming_patterns["resource_type"]["workload"]
# Usage: local.naming_patterns["azurerm_resource_group"]["sales"]
# Returns: "rg-a10corp-sales-dev"
#
# Format (3 branches):
#   1. Resources in no_hyphen_resources:
#      - include_env=true  => {prefix}{org}{workload}{env} (e.g., "sta10corpsalesdev")
#      - include_env=false => {prefix}{org}{workload} (e.g., "sta10corpsales")
#   2. Standard resources with environment:
#      - include_env=true  => {prefix}-{org}-{workload}-{env} (e.g., "rg-a10corp-sales-dev")
#   3. Standard resources without environment:
#      - include_env=false => {prefix}-{org}-{workload} (e.g., "mg-a10corp-sales")
# ============================================================

locals {
  # Resources that don't support hyphens (alphanumeric only)
  no_hyphen_resources = toset(["azurerm_storage_account", "azurerm_container_registry"])

  naming_patterns = {
    for resource, include_env in local.resource_include_env :
    resource => {
      for workload in local.workloads :
      workload => lower(join(
        contains(local.no_hyphen_resources, resource) ? "" : "-",
        compact([
          local.resource_type_map[resource],
          var.org_name,
          workload,
          include_env ? var.environment : null
        ])
      ))
    }
  }
}

# ============================================================
# Guardrails (fail fast if config is inconsistent)
# ============================================================

resource "null_resource" "validate_caf_naming" {
  lifecycle {
    precondition {
      condition     = length(local.missing_prefix_keys) == 0
      error_message = "CAF naming config error: resource_type_map missing prefixes for: ${join(", ", tolist(local.missing_prefix_keys))}"
    }

    precondition {
      condition     = length(local.unruled_resource_types) == 0
      error_message = "CAF naming config error: resource_include_env missing rules for: ${join(", ", tolist(local.unruled_resource_types))}"
    }
  }
}