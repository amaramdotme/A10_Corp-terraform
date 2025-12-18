# Workloads Module

This module manages environment-specific resource groups for A10 Corp workloads. These resources can be safely destroyed and recreated without affecting the organizational foundation.

## Purpose

- **Environment-specific resources** - Separate resource groups per environment (dev/stage/prod)
- **Safe lifecycle** - Can be destroyed and recreated as needed
- **Workload isolation** - Separate resource groups for each business unit

## Lifecycle

✅ **Safe to destroy** - This module can be destroyed without affecting the foundation (management groups). Resources are environment-specific and can be recreated.

## Resources Managed

### Resource Groups (per environment)
- `rg-a10corp-shared-{env}` - Common/shared resources (deployed to HQ subscription)
- `rg-a10corp-sales-{env}` - Sales business unit resources (deployed to Sales subscription)
- `rg-a10corp-service-{env}` - Service business unit resources (deployed to Service subscription)

## Usage

This module is called by the `workloads/` root module:

```hcl
module "workloads" {
  source = "../modules/workloads"

  # Naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Configuration
  location    = var.location
  common_tags = var.common_tags
}
```

## Provider Configuration

**Important**: The parent module must configure **aliased providers** to direct each resource group to the correct subscription:

```hcl
# In workloads/providers.tf (parent module)
provider "azurerm" {
  alias           = "hq"
  subscription_id = local.hq_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "sales"
  subscription_id = local.sales_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "service"
  subscription_id = local.service_subscription_id
  features {}
}

# Then in workloads/main.tf (parent module)
module "workloads" {
  source = "../modules/workloads"

  providers = {
    azurerm.hq      = azurerm.hq
    azurerm.sales   = azurerm.sales
    azurerm.service = azurerm.service
  }

  # ... other variables
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| naming_patterns | Map of resource names from common module | `map(map(string))` | yes | n/a |
| location | Azure region for resources | `string` | no | `"eastus"` |
| common_tags | Common tags for resources | `map(string)` | no | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_shared_id | ID of the shared resource group |
| resource_group_shared_name | Name of the shared resource group |
| resource_group_sales_id | ID of the sales resource group |
| resource_group_sales_name | Name of the sales resource group |
| resource_group_service_id | ID of the service resource group |
| resource_group_service_name | Name of the service resource group |
| all_resource_groups | Map of all RG names and IDs |

## Resource Placement

| Resource Group | Subscription | Management Group |
|----------------|--------------|------------------|
| rg-a10corp-shared-{env} | sub-hq | mg-a10corp-hq |
| rg-a10corp-sales-{env} | sub-sales | mg-a10corp-sales |
| rg-a10corp-service-{env} | sub-service | mg-a10corp-service |

## Dependencies

- **Common Module**: Provides naming patterns
- **Parent Module**: Provides aliased providers for subscription routing

## Environment Examples

```
Dev:
- rg-a10corp-shared-dev
- rg-a10corp-sales-dev
- rg-a10corp-service-dev

Stage:
- rg-a10corp-shared-stage
- rg-a10corp-sales-stage
- rg-a10corp-service-stage

Prod:
- rg-a10corp-shared-prod
- rg-a10corp-sales-prod
- rg-a10corp-service-prod
```

## Safe Operations

The following operations are safe for this module:

```bash
# Destroy dev environment (won't affect stage/prod)
cd workloads/
terraform destroy -var-file="environments/dev.tfvars"

# Recreate dev environment
terraform apply -var-file="environments/dev.tfvars"
```

## Notes

- Resource groups use CAF naming with environment suffix (e.g., `rg-a10corp-sales-dev`)
- Each RG is deployed to its designated subscription via aliased providers
- Tags are automatically merged with workload-specific tags

## Author

A10 Corporation Infrastructure Team

## Last Updated

2025-12-17
