# Workloads Root Caller

This directory contains the root module for deploying **environment-specific workload resources** (resource groups, VMs, databases, etc.).

## Purpose

- **Environment-aware**: Separate deployments for dev, stage, and prod
- **Resource groups**: Creates RGs for shared, sales, and service workloads
- **Frequent changes**: Expected to change often as workloads evolve

## Architecture

```
workloads/
├── main.tf           # Calls common + workloads modules
├── variables.tf      # Just environment variable
├── providers.tf      # Default + aliased providers (hq, sales, service)
├── backend.tf        # Remote state config (partial)
├── outputs.tf        # Resource group outputs
└── environments/     # Environment-specific configs
    ├── dev.tfvars
    ├── stage.tfvars
    ├── prod.tfvars
    ├── backend-dev.hcl
    ├── backend-stage.hcl
    └── backend-prod.hcl
```

## Module Dependencies

```
workloads/main.tf
├── module "common"    (../modules/common)
│   ├── Naming patterns
│   ├── Key Vault data sources
│   └── Subscription IDs
└── module "workloads" (../modules/workloads)
    └── Resource group creation
```

## Usage

### Development Environment

```bash
# Navigate to workloads directory
cd workloads/

# Initialize with dev backend
terraform init -backend-config="environments/backend-dev.hcl"

# Plan dev deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply dev deployment
terraform apply -var-file="environments/dev.tfvars"
```

### Staging Environment

```bash
# Re-initialize with stage backend (switches state file)
terraform init -reconfigure -backend-config="environments/backend-stage.hcl"

# Plan stage deployment
terraform plan -var-file="environments/stage.tfvars"

# Apply stage deployment
terraform apply -var-file="environments/stage.tfvars"
```

### Production Environment

```bash
# Re-initialize with prod backend (switches state file)
terraform init -reconfigure -backend-config="environments/backend-prod.hcl"

# Plan prod deployment
terraform plan -var-file="environments/prod.tfvars"

# Apply prod deployment
terraform apply -var-file="environments/prod.tfvars"
```

## State Management

Each environment has its own state file in Azure Storage:

- **Container**: `workloads` (in `storerootblob` storage account)
- **Dev state**: `workloads-dev.tfstate`
- **Stage state**: `workloads-stage.tfstate`
- **Prod state**: `workloads-prod.tfstate`

## Provider Configuration

### Default Provider (sub-root)
- Used by common module to access Key Vault
- Authenticates via ARM_SUBSCRIPTION_ID environment variable or OIDC

### Aliased Providers
- **hq**: Uses `module.common.hq_subscription_id`
- **sales**: Uses `module.common.sales_subscription_id`
- **service**: Uses `module.common.service_subscription_id`

Subscription IDs are fetched from Key Vault at runtime (no secrets in code).

## What Gets Created

For each environment (dev/stage/prod):

- **rg-a10corp-shared-{env}**: Shared workload resource group
- **rg-a10corp-sales-{env}**: Sales workload resource group
- **rg-a10corp-service-{env}**: Service workload resource group

Example for dev environment:
- `rg-a10corp-shared-dev`
- `rg-a10corp-sales-dev`
- `rg-a10corp-service-dev`

## CI/CD

See `.github/workflows/workloads-deploy.yml` for automated deployments via GitHub Actions.

## Important Notes

1. **Always specify environment**: Use `-var-file="environments/{env}.tfvars"`
2. **Always specify backend**: Use `-backend-config="environments/backend-{env}.hcl"`
3. **Use -reconfigure when switching environments**: Prevents state file mix-ups
4. **No variables.tf duplication**: All defaults come from common module
5. **No secrets in code**: Subscription IDs fetched from Key Vault at runtime

## Troubleshooting

### Wrong state file
```bash
# Re-initialize with correct backend
terraform init -reconfigure -backend-config="environments/backend-dev.hcl"
```

### Provider authentication errors
```bash
# Verify Azure login
az login
az account show

# Verify environment variables (local dev)
echo $ARM_SUBSCRIPTION_ID
echo $ARM_TENANT_ID
```

### Key Vault access denied
```bash
# Verify Key Vault access
az keyvault secret show \
  --vault-name kv-root-terraform \
  --name terraform-dev-hq-sub-id
```
