# Foundation Deployment

This directory deploys the organizational foundation for A10 Corp Azure infrastructure.

> **CI/CD**: Changes to foundation trigger automated workflows via GitHub Actions.

## Purpose

- **One-time deployment** per Azure tenant
- Creates management group hierarchy
- Associates subscriptions to management groups
- **No environment variants** - deployed once globally

## What Gets Deployed

### Management Groups
- `mg-a10corp-hq` - Root/parent management group
- `mg-a10corp-sales` - Sales business unit (child of HQ)
- `mg-a10corp-service` - Service business unit (child of HQ)

### Subscription Associations
- HQ subscription → `mg-a10corp-hq`
- Sales subscription → `mg-a10corp-sales`
- Service subscription → `mg-a10corp-service`

## Prerequisites

1. **Azure CLI authenticated**:
   ```bash
   az login
   ```

2. **Environment variables set** (for local development):
   ```bash
   source ../.env
   ```
   The `.env` file should contain:
   ```bash
   export ARM_SUBSCRIPTION_ID="<sub-root-id>"  # Root subscription (where Key Vault lives)
   export ARM_TENANT_ID="<tenant-id>"
   ```

3. **Key Vault access**: User must have "Key Vault Secrets Officer" role on `kv-root-terraform`

4. **Pre-existing infrastructure**:
   - ✅ Resource Group: `rg-root-iac`
   - ✅ Key Vault: `kv-root-terraform`
   - ✅ Storage Account: `storerootblob`
   - ✅ Storage Container: `foundation`

## Deployment

### Initial Deployment

```bash
cd foundation/

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply changes
terraform apply
```

### No .tfvars Files Needed

Foundation uses defaults from the common module. There are no environment-specific variables to set!

## How It Works

### Module Flow

```
foundation/main.tf
    ↓
    ├─→ module "common"
    │   - Fetches subscription IDs from Key Vault
    │   - Generates naming patterns
    │   - Uses default values for org_name, location, tags
    │
    └─→ module "foundation"
        - Creates management groups using names from common
        - Associates subscriptions using IDs from common
```

### Key Design Decisions

1. **No variables.tf** - All configuration comes from common module defaults
2. **No environment parameter** - Foundation is global, not environment-specific
3. **No data-sources.tf** - Common module handles Key Vault fetching
4. **Single state file** - `foundation.tfstate` (not per-environment)

## State Management

**Backend**: Azure Storage
- **Resource Group**: `rg-root-iac`
- **Storage Account**: `storerootblob`
- **Container**: `foundation`
- **State File**: `terraform.tfstate`

## Outputs

After deployment, the following outputs are available:

```hcl
output "management_groups" {
  value = {
    hq      = { id = "...", name = "mg-a10corp-hq" }
    sales   = { id = "...", name = "mg-a10corp-sales" }
    service = { id = "...", name = "mg-a10corp-service" }
  }
}
```

## Important Notes

### ⚠️ Never Destroy Foundation

Foundation is **permanent infrastructure**. Destroying it will:
- Remove the management group hierarchy
- Break subscription organization
- Potentially impact policies and governance

### When to Update Foundation

Only update foundation when:
- Adding new management groups
- Reorganizing the MG hierarchy
- Moving subscriptions between MGs

### No Environment Variants

Unlike workloads, foundation does NOT have dev/stage/prod variants. The same MG structure applies to all environments.

## Troubleshooting

### Error: "Key Vault not found"
- Ensure you're authenticated to the correct Azure tenant
- Verify ARM_SUBSCRIPTION_ID points to sub-root (where Key Vault lives)

### Error: "Subscription not found"
- Check that subscription IDs exist in Key Vault:
  - `terraform-dev-hq-sub-id`
  - `terraform-dev-sales-sub-id`
  - `terraform-dev-service-sub-id`

### Error: "Management group already exists"
- If MGs already exist, use `terraform import` before running apply

## See Also

- [Common Module](../modules/common/README.md) - Shared configuration
- [Foundation Module](../modules/foundation/README.md) - Management group logic
- [DECISIONS.md](../docs/DECISIONS.md) - Architectural decisions

## Last Updated

2025-12-18 try deploy 2 after RBAC adjustments
