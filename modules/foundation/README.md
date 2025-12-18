# Foundation Module

This module manages the organizational foundation for A10 Corp Azure infrastructure, including management groups and subscription associations.

## Purpose

- **One-time setup** - Rarely changed, never destroyed
- **Organizational structure** - Management group hierarchy
- **Subscription placement** - Associates subscriptions to management groups

## Lifecycle

⚠️ **Important**: This module should be created once and maintained carefully. Destroying this module will affect the entire organizational structure.

## Resources Managed

### Management Groups
- `mg-a10corp-hq` - Root/parent management group (HQ)
- `mg-a10corp-sales` - Sales business unit (child of HQ)
- `mg-a10corp-service` - Service business unit (child of HQ)

### Subscription Associations
- HQ subscription → `mg-a10corp-hq`
- Sales subscription → `mg-a10corp-sales`
- Service subscription → `mg-a10corp-service`

## Usage

This module is called by the `foundation/` root module:

```hcl
module "foundation" {
  source = "../modules/foundation"

  # Naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Subscription IDs from Key Vault (via data sources in parent)
  tenant_id               = local.tenant_id
  hq_subscription_id      = local.hq_subscription_id
  sales_subscription_id   = local.sales_subscription_id
  service_subscription_id = local.service_subscription_id

  # Tags
  common_tags = var.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Sensitive |
|------|-------------|------|----------|-----------|
| naming_patterns | Map of resource names from common module | `map(map(string))` | yes | no |
| tenant_id | Azure Tenant ID | `string` | yes | yes |
| hq_subscription_id | HQ subscription ID | `string` | yes | yes |
| sales_subscription_id | Sales subscription ID | `string` | yes | yes |
| service_subscription_id | Service subscription ID | `string` | yes | yes |
| common_tags | Common tags for resources | `map(string)` | no | no |

## Outputs

| Name | Description |
|------|-------------|
| management_group_hq_id | ID of the HQ management group |
| management_group_hq_name | Display name of HQ MG |
| management_group_sales_id | ID of the Sales management group |
| management_group_sales_name | Display name of Sales MG |
| management_group_service_id | ID of the Service management group |
| management_group_service_name | Display name of Service MG |
| subscription_associations | Map of subscription association IDs |

## Architecture

```
Tenant Root Group
└── mg-a10corp-hq (HQ)
    ├── mg-a10corp-sales (Sales)
    └── mg-a10corp-service (Service)
```

## Dependencies

- **Common Module**: Provides naming patterns
- **Parent Module**: Provides subscription IDs from Key Vault

## Notes

- Subscription IDs are **not stored in this module** - they come from the parent module's Key Vault data sources
- Management groups use CAF naming without environment suffix (e.g., `mg-a10corp-sales`)
- This module does **not** create subscriptions, only associates existing ones

## Author

A10 Corporation Infrastructure Team

## Last Updated

2025-12-17
