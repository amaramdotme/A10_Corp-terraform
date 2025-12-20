# Policies Module

This module manages Azure Policy assignments for A10 Corp governance.

## Functionality
It assigns the following Built-in Policies to a specified Management Group:
1. **Enforce Environment Tag**: Requires the `Environment` tag on all Resource Groups.
2. **Allowed Locations**: Restricts resource deployment to the specified region (e.g., `eastus`).

## Usage
Called by the Foundation module to enforce rules at the organizational level (`mg-a10corp-hq`).

```hcl
module "policies" {
  source              = "../modules/policies"
  management_group_id = module.foundation.hq_management_group_id
  location            = module.common.location
}
```
