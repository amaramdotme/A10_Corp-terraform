# Azure CAF Naming Convention
# This file defines naming standards following Azure Cloud Adoption Framework

# ============================================================
# Resource Type Mappings + Rules
# ============================================================

locals {
  # Map Azure resource types to their CAF resource type prefixes
  resource_type_map = {
    "azurerm_resource_group"   = "rg"
    "azurerm_management_group" = "mg"
    "azurerm_virtual_machine"  = "vm"
    "azurerm_policy_group"     = "pg"
    # Add more resource types as needed
    # "azurerm_storage_account"   = "st"
    # "azurerm_virtual_network"   = "vnet"
  }

  # Global workloads list
  workloads = ["hq", "shared", "sales", "service"]

  # SINGLE SOURCE OF TRUTH:
  # include_env = true  => {prefix}-{org}-{workload}-{env}
  # include_env = false => {prefix}-{org}-{workload}
  resource_include_env = {
    "azurerm_resource_group"   = true
    "azurerm_virtual_machine"  = true
    "azurerm_management_group" = false
    "azurerm_policy_group"     = false
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
# Format:
#   include_env=true  => {resource_type}-{org_name}-{workload}-{environment}
#   include_env=false => {resource_type}-{org_name}-{workload}
# ============================================================

locals {
  naming_patterns = {
    for resource, include_env in local.resource_include_env :
    resource => {
      for workload in local.workloads :
      workload => lower(join("-", compact([
        local.resource_type_map[resource],
        var.org_name,
        workload,
        include_env ? var.environment : null
      ])))
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
