# Common Module

This module provides shared naming logic and variables for the A10 Corp Terraform infrastructure. It follows Azure Cloud Adoption Framework (CAF) naming conventions and is used by both the foundation and workloads modules.

## Purpose

- **Single source of truth** for naming patterns
- **Consistency** across all infrastructure
- **Testability** - naming logic can be tested independently
- **Reusability** - shared by multiple parent modules

## Features

- CAF-compliant resource naming
- Environment-aware naming (dev/stage/prod)
- Workload-specific naming (hq, shared, sales, service)
- Built-in validation for configuration consistency
- Comprehensive outputs for parent modules

## Usage

### In Foundation Module

```hcl
module "common" {
  source = "../modules/common"

  org_name    = var.org_name
  environment = var.environment
  location    = var.location
  common_tags = var.common_tags
}

# Use naming patterns from common module
resource "azurerm_management_group" "sales" {
  display_name = module.common.naming_patterns["azurerm_management_group"]["sales"]
  # Returns: "mg-a10corp-sales"
}
```

### In Workloads Module

```hcl
module "common" {
  source = "../modules/common"

  org_name    = var.org_name
  environment = var.environment
  location    = var.location
  common_tags = var.common_tags
}

# Use naming patterns from common module
resource "azurerm_resource_group" "sales" {
  name     = module.common.naming_patterns["azurerm_resource_group"]["sales"]
  # Returns: "rg-a10corp-sales-dev"
  location = module.common.location
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (dev, stage, prod) | `string` | n/a | yes |
| location | Azure region for resources | `string` | `"eastus"` | no |
| org_name | Organization name for naming | `string` | `"a10corp"` | no |
| common_tags | Common tags for all resources | `map(string)` | See variables.tf | no |

## Outputs

| Name | Description |
|------|-------------|
| naming_patterns | Map of resource types to workload-specific names |
| org_name | Organization name used in naming |
| environment | Environment name (dev/stage/prod) |
| location | Azure region |
| common_tags | Common tags map |
| workloads | List of all workload identifiers |

## Naming Pattern Examples

### Resource Groups (include environment)
- `rg-a10corp-shared-dev`
- `rg-a10corp-sales-dev`
- `rg-a10corp-service-prod`

### Management Groups (no environment)
- `mg-a10corp-hq`
- `mg-a10corp-sales`
- `mg-a10corp-service`

## Adding New Resource Types

To add a new resource type:

1. Add to `resource_type_map` with CAF prefix:
```hcl
"azurerm_storage_account" = "st"
```

2. Add to `resource_include_env` with true/false:
```hcl
"azurerm_storage_account" = true  # Include environment suffix
```

3. Built-in validation will fail if maps are inconsistent (fail-fast design)

## Testing

Test the module independently with `terraform console`:

```bash
cd modules/common/
terraform init
terraform console -var="environment=dev"

# Try these commands:
> local.naming_patterns["azurerm_resource_group"]["sales"]
"rg-a10corp-sales-dev"

> local.naming_patterns["azurerm_management_group"]["hq"]
"mg-a10corp-hq"
```

## Workload Definitions

- **hq**: Management group only (no resource groups)
- **shared**: Common resources (deployed to HQ subscription)
- **sales**: Sales business unit resources
- **service**: Service business unit resources

## Validation

The module includes built-in validation:

- **Config Consistency**: Ensures `resource_type_map` and `resource_include_env` are synchronized
- **Environment Values**: Only allows dev/stage/prod
- **Naming Format**: Validates org_name and location formats
- **Required Tags**: Ensures ManagedBy tag is present

## Architecture

This module is called by:
- `foundation/` root module
- `workloads/` root module

There are no dependencies between foundation and workloads - both independently call this common module.

```
foundation/              workloads/
    ↓                        ↓
    └─────→ modules/common ←─┘
```

## Author

A10 Corporation Infrastructure Team

## Last Updated

2025-12-17
