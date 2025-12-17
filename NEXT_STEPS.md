# Next Steps: Two-Module Refactoring

This document outlines the plan to refactor the current Terraform code into a two-module architecture.

## Current State (as of 2025-12-17)

**Terraform-Managed Resources**: None (infrastructure destroyed, ready for restructure)

**Pre-Terraform Infrastructure (Already Complete):**
- ✅ Resource Group: `rg-root-iac` in sub-root subscription
- ✅ Key Vault: `kv-root-terraform`
  - Contains secrets: `terraform-dev-sensitive`, `terraform-stage-sensitive`, `terraform-prod-sensitive`
  - Contains per-environment subscription IDs: `terraform-{env}-tenant-id`, `terraform-{env}-hq-sub-id`, etc.
  - RBAC: User assigned "Key Vault Secrets Officer" role
  - Public network access: Enabled
- ✅ Storage Account: `storerootblob`
  - Containers: `foundation-dev`, `foundation-stage`, `foundation-prod`, `workloads-dev`, `workloads-stage`, `workloads-prod`
  - Blob versioning: Enabled
  - Soft delete: Enabled (7 days)

**Azure Subscriptions (4 total):**
- sub-root: [ID in Key Vault] - Root subscription (stays in Tenant Root MG)
- sub-hq: [ID in Key Vault] - HQ subscription (will move to mg-a10corp-hq)
- sub-sales: [ID in Key Vault] - Sales subscription (will move to mg-a10corp-sales)
- sub-service: [ID in Key Vault] - Service subscription (will move to mg-a10corp-service)

**Current Architecture**: Monolithic structure (all resources in root directory)

---

## Design Goals

### Pre-Terraform Setup (Already Complete)
1. ✅ Tenant Root Management Group (Azure default)
2. ✅ Four Azure Subscriptions (sub-root, sub-hq, sub-sales, sub-service)
3. ✅ Resource Group: `rg-root-iac` (in sub-root subscription)
4. ✅ Key Vault: `kv-root-terraform` (for sensitive values and subscription IDs)
5. ✅ Storage Account: `storerootblob` (for remote state with 6 containers)
6. ✅ Native Key Vault integration via Terraform data sources (see [data-sources.tf](data-sources.tf))

### Module 1: Foundation (One-time Setup)
**Purpose**: Organizational structure that rarely changes
**Lifecycle**: Create once, never destroy

**Resources**:
- Management Groups (HQ, Sales, Service)
- Subscription assignments to MGs

**State File**: `foundation-<env>.tfstate` in Azure Storage

### Module 2: Workloads (Environment-specific)
**Purpose**: Resource Groups per environment
**Lifecycle**: Can be destroyed and recreated safely

**Resources**:
- Resource Groups per environment for each workload (shared, sales, service)

**State File**: `workloads-<env>.tfstate` in Azure Storage

---

## New Directory Structure

```
terraform_iac/
├── foundation/                          # Module 1 root
│   ├── backend.tf                       # Remote state config (Azure Storage)
│   ├── providers.tf                     # Provider config with Key Vault data sources
│   ├── data-sources.tf                  # Key Vault data sources for subscription IDs
│   ├── main.tf                          # Calls foundation module
│   ├── outputs.tf                       # Output MG IDs for workloads module
│   ├── environments/
│   │   ├── dev.tfvars                   # Non-sensitive only (safe for git)
│   │   ├── stage.tfvars                 # Non-sensitive only (safe for git)
│   │   └── prod.tfvars                  # Non-sensitive only (safe for git)
│   └── README.md                        # Module 1 docs
│
├── workloads/                           # Module 2 root
│   ├── backend.tf                       # Remote state config (Azure Storage)
│   ├── providers.tf                     # Provider config with Key Vault data sources
│   ├── data-sources.tf                  # Key Vault + foundation outputs
│   ├── main.tf                          # Calls workloads module
│   ├── outputs.tf                       # Output RG names
│   ├── environments/
│   │   ├── dev.tfvars                   # Non-sensitive only (safe for git)
│   │   ├── stage.tfvars                 # Non-sensitive only (safe for git)
│   │   └── prod.tfvars                  # Non-sensitive only (safe for git)
│   └── README.md                        # Module 2 docs
│
├── modules/                             # Reusable modules
│   ├── foundation/                      # Foundation module code
│   │   ├── main.tf                      # Management Groups
│   │   ├── subscriptions.tf             # Subscription assignments
│   │   ├── variables.tf                 # Input variables
│   │   ├── outputs.tf                   # Output MG IDs
│   │   └── naming.tf                    # Naming logic for MGs
│   └── workloads/                       # Workloads module code
│       ├── main.tf                      # Resource Groups
│       ├── variables.tf                 # Input variables
│       ├── outputs.tf                   # Output RG names
│       └── naming.tf                    # Naming logic for RGs
│
├── .github/workflows/                   # CI/CD workflows
│   ├── foundation-deploy.yml            # Foundation deployment
│   └── workloads-deploy.yml             # Workloads deployment
│
└── [legacy files to archive]            # Current monolithic files
    ├── providers.tf
    ├── data-sources.tf
    ├── management-groups.tf
    ├── subscriptions.tf
    ├── resource-groups.tf
    ├── naming.tf
    └── environments/*.tfvars
```

## Key Changes from Original Plan

This updated plan reflects the **native Key Vault integration** approach implemented in the current codebase:

### What Changed
1. **No external scripts needed** - Terraform data sources fetch values directly from Key Vault
2. **No sensitive .tfvars files** - All subscription IDs fetched at runtime
3. **No secure/ directory** - All .tfvars files are safe for git
4. **Simplified workflow** - Just `source .env && terraform plan`
5. **Already complete** - Pre-Terraform infrastructure (Key Vault, Storage) is ready

### What Stayed the Same
1. Two-module architecture (foundation + workloads)
2. Remote state in Azure Storage (separate state files per module)
3. Multi-environment support (dev, stage, prod)
4. OIDC authentication for GitHub Actions
5. CAF-compliant naming patterns

### Migration Advantages
- ✅ Simpler local development (no script execution)
- ✅ Fewer security risks (no sensitive files on disk)
- ✅ Better audit trail (Key Vault logs all secret access)
- ✅ Less to maintain (no scripts, no sensitive .tfvars management)
- ✅ Same developer experience (terraform plan/apply commands unchanged)

---

---

## Key Vault Integration Strategy

**Approach**: Native Terraform data sources (no external scripts needed)

### How It Works
1. **Default Provider**: Authenticates using `.env` file (local) or OIDC (CI/CD)
2. **Data Sources**: Terraform fetches subscription/tenant IDs directly from Key Vault
3. **Aliased Providers**: HQ, Sales, Service providers use the fetched subscription IDs
4. **No Circular Dependency**: Default provider uses root subscription, aliased providers use Key Vault values

### Key Vault Secrets Structure

**Per-Environment Subscription IDs** (individual secrets):
- `terraform-dev-tenant-id`
- `terraform-dev-hq-sub-id`
- `terraform-dev-sales-sub-id`
- `terraform-dev-service-sub-id`
- (Repeat pattern for stage/prod)

**Combined Sensitive Values** (optional, for backup):
- `terraform-dev-sensitive` (contains all sensitive .tfvars content)
- `terraform-stage-sensitive`
- `terraform-prod-sensitive`

### .tfvars Structure

#### Foundation Module - `foundation/environments/dev.tfvars`
```hcl
# All values safe for git - no secrets
org_name    = "a10corp"
environment = "dev"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
  Module      = "Foundation"
}

# Subscription IDs fetched from Key Vault via data sources (not in .tfvars)
```

#### Workloads Module - `workloads/environments/dev.tfvars`
```hcl
# All values safe for git - no secrets
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
  Module      = "Workloads"
}

# Subscription IDs fetched from Key Vault via data sources (not in .tfvars)
```

**Note**: With native Key Vault integration, there are NO sensitive .tfvars files to manage. All sensitive values are fetched at runtime via Terraform data sources.

---

## Implementation Steps

### Phase 1: Infrastructure Preparation ✅ COMPLETE
- [x] 1.1. Create Resource Group for Terraform state: `rg-root-iac`
- [x] 1.2. Create Storage Account: `storerootblob`
- [x] 1.3. Create containers: `foundation-dev/stage/prod`, `workloads-dev/stage/prod`
- [x] 1.4. Create Key Vault: `kv-root-terraform`
- [x] 1.5. Configure Key Vault RBAC and upload sensitive secrets
- [x] 1.6. Enable blob versioning and soft delete on storage account

### Phase 2: Code Refactoring
- [ ] 2.1. Create module directories (`modules/foundation/`, `modules/workloads/`)
- [ ] 2.2. Create root directories (`foundation/`, `workloads/`)
- [ ] 2.3. Split `management-groups.tf` and `subscriptions.tf` → `modules/foundation/`
- [ ] 2.4. Split `resource-groups.tf` → `modules/workloads/`
- [ ] 2.5. Split `naming.tf` into module-specific naming logic
- [ ] 2.6. Create `foundation/main.tf` that calls foundation module
- [ ] 2.7. Create `workloads/main.tf` that calls workloads module
- [ ] 2.8. Create `workloads/data.tf` to reference foundation outputs (if needed)

### Phase 3: Variables & Data Sources
- [ ] 3.1. Create non-sensitive .tfvars in `foundation/environments/` (safe for git)
- [ ] 3.2. Create non-sensitive .tfvars in `workloads/environments/` (safe for git)
- [ ] 3.3. Create `foundation/data-sources.tf` with Key Vault data sources
- [ ] 3.4. Create `workloads/data-sources.tf` with Key Vault data sources
- [ ] 3.5. Update variables.tf for each module (remove subscription ID variables)

### Phase 4: Backend Configuration
- [ ] 4.1. Create `foundation/backend.tf` with Azure Storage backend
- [ ] 4.2. Create `workloads/backend.tf` with Azure Storage backend
- [ ] 4.3. Configure separate state files for each module

### Phase 5: Provider Configuration
- [ ] 5.1. Create `foundation/providers.tf` with default provider + Key Vault integration
- [ ] 5.2. Create `workloads/providers.tf` with default provider + Key Vault integration
- [ ] 5.3. Configure aliased providers (hq, sales, service) using Key Vault data sources
- [ ] 5.4. Verify provider authentication works locally

### Phase 6: Key Vault Verification ✅ MOSTLY COMPLETE
- [x] 6.1. Verify individual subscription ID secrets exist in Key Vault
  - `terraform-dev-tenant-id`, `terraform-dev-hq-sub-id`, etc.
- [x] 6.2. Verify combined sensitive secrets (for backup/reference)
  - `terraform-dev-sensitive`, `terraform-stage-sensitive`, `terraform-prod-sensitive`
- [ ] 6.3. Test data source fetching locally with `terraform console`

### Phase 7: GitHub Actions Workflows
- [ ] 7.1. Create `.github/workflows/foundation-deploy.yml` with OIDC authentication
- [ ] 7.2. Create `.github/workflows/workloads-deploy.yml` with OIDC authentication
- [ ] 7.3. Verify workflows use Azure login (no Key Vault script fetching needed)
- [ ] 7.4. Archive old `terraform-deploy.yml` workflow

### Phase 8: State Migration
- [ ] 8.1. Backup current state file (`terraform.tfstate`)
- [ ] 8.2. Initialize foundation module with remote backend
- [ ] 8.3. Import existing management groups to foundation state
- [ ] 8.4. Import existing subscription associations to foundation state
- [ ] 8.5. Initialize workloads module with remote backend
- [ ] 8.6. Import existing resource groups to workloads state
- [ ] 8.7. Verify no resources in old state file
- [ ] 8.8. Archive old terraform files

### Phase 9: Testing
- [ ] 9.1. Test foundation module locally (dev)
  - `terraform plan` (should show no changes)
- [ ] 9.2. Test workloads module locally (dev)
  - `terraform plan` (should show no changes)
- [ ] 9.3. Test foundation GitHub Actions workflow
- [ ] 9.4. Test workloads GitHub Actions workflow
- [ ] 9.5. Test destroy/recreate of workloads (dev only)

### Phase 10: Documentation
- [ ] 10.1. Update `CLAUDE.md` with new module structure
- [ ] 10.2. Create `foundation/README.md`
- [ ] 10.3. Create `workloads/README.md`
- [ ] 10.4. Update `DECISIONS.md` with module separation decision
- [ ] 10.5. Update `TERRAFORM_COMMANDS.md` with new workflows
- [ ] 10.6. Create team onboarding guide

### Phase 11: Rollout
- [ ] 11.1. Deploy foundation to stage
- [ ] 11.2. Deploy workloads to stage
- [ ] 11.3. Deploy foundation to prod
- [ ] 11.4. Deploy workloads to prod
- [ ] 11.5. Update repository to allow non-sensitive .tfvars
- [ ] 11.6. Commit all changes
- [ ] 11.7. Consider making repository public (optional)

---

## Local Development Workflow (After Migration)

### Prerequisites
```bash
# 1. Authenticate with Azure
az login

# 2. Load environment variables (sets ARM_SUBSCRIPTION_ID and ARM_TENANT_ID for default provider)
source .env
```

### Apply Foundation (One-time)
```bash
cd foundation/
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

**How it works:**
- Default provider uses `.env` file (ARM_SUBSCRIPTION_ID = sub-root)
- Data sources fetch subscription IDs from Key Vault
- Aliased providers (hq, sales, service) use fetched subscription IDs
- No sensitive .tfvars files needed!

### Apply Workloads (Repeatable)
```bash
cd workloads/
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Destroy Workloads (Safe - doesn't affect foundation)
```bash
cd workloads/
terraform destroy -var-file="environments/dev.tfvars"
```

---

## GitHub Actions Workflow (After Migration)

### Foundation Deployment
1. Navigate to: Actions → Deploy Foundation
2. Select environment: dev/stage/prod
3. Select action: plan/apply
4. Workflow authenticates with Azure via OIDC (sets ARM_SUBSCRIPTION_ID and ARM_TENANT_ID)
5. Terraform fetches subscription IDs from Key Vault via data sources
6. Runs terraform plan/apply

### Workloads Deployment
1. Navigate to: Actions → Deploy Workloads
2. Select environment: dev/stage/prod
3. Select action: plan/apply/destroy
4. Workflow authenticates with Azure via OIDC
5. Terraform fetches subscription IDs from Key Vault via data sources
6. Runs terraform plan/apply/destroy

**Key Benefit**: No need to manually fetch secrets from Key Vault - Terraform does it automatically!

---

## Rollback Plan

If migration fails:
1. Restore backup of `terraform.tfstate`
2. Revert code changes
3. Run `terraform plan` to verify state
4. Document issues encountered

---

## Success Criteria

✅ Foundation module deploys successfully without changes
✅ Workloads module deploys successfully without changes
✅ Can destroy/recreate workloads without affecting foundation
✅ GitHub Actions workflows execute successfully
✅ Local development workflow functions correctly
✅ All documentation updated
✅ State files properly separated in Azure Storage

---

## Benefits of This Approach

1. **Separation of Concerns**: Stable foundation vs dynamic workloads
2. **Safe Operations**: Destroy/recreate RGs without risk to MGs
3. **Independent State**: Each module has isolated state
4. **Scalability**: Easy to add new workloads or environments
5. **Security**: Sensitive values in Key Vault, non-sensitive in repo
6. **CI/CD Ready**: Separate workflows for foundation vs workloads
7. **Team Collaboration**: Non-sensitive config versioned in Git

---

## Key Changes from Original Plan

This updated plan reflects the **native Key Vault integration** approach implemented in the current codebase:

### What Changed
1. **No external scripts needed** - Terraform data sources fetch values directly from Key Vault
2. **No sensitive .tfvars files** - All subscription IDs fetched at runtime
3. **No secure/ directory** - All .tfvars files are safe for git
4. **Simplified workflow** - Just `source .env && terraform plan`
5. **Already complete** - Pre-Terraform infrastructure (Key Vault, Storage) is ready

### What Stayed the Same
1. Two-module architecture (foundation + workloads)
2. Remote state in Azure Storage (separate state files per module)
3. Multi-environment support (dev, stage, prod)
4. OIDC authentication for GitHub Actions
5. CAF-compliant naming patterns

### Migration Advantages
- ✅ Simpler local development (no script execution)
- ✅ Fewer security risks (no sensitive files on disk)
- ✅ Better audit trail (Key Vault logs all secret access)
- ✅ Less to maintain (no scripts, no sensitive .tfvars management)
- ✅ Same developer experience (terraform plan/apply commands unchanged)

---

**Last Updated**: 2025-12-17
**Status**: Infrastructure Ready - Code Refactoring Phase
**Next Action**: Begin Phase 2 (Code Refactoring)
