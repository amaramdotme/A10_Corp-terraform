# Next Steps: Three-Module Refactoring

This document outlines the plan to refactor the current Terraform code into a **three-module architecture** with shared common logic.

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

## Architecture Clarification

### Workload Definitions

After analyzing the current code, here's the actual workload structure:

**Management Groups (Foundation Module):**
- `mg-a10corp-hq` - Root/parent management group
- `mg-a10corp-sales` - Sales business unit (child of hq)
- `mg-a10corp-service` - Service business unit (child of hq)

**Resource Groups (Workloads Module):**
- `rg-a10corp-shared-{env}` - Shared/common resources (deployed to HQ subscription)
- `rg-a10corp-sales-{env}` - Sales workload resources (deployed to Sales subscription)
- `rg-a10corp-service-{env}` - Service workload resources (deployed to Service subscription)

**Key Insight**:
- **"HQ"** is a management group only (no dedicated resource groups)
- **"Shared"** provides common resources but lives in the HQ subscription
- This means we have **3 MGs** (hq, sales, service) and **3 RG patterns** (shared, sales, service)

---

## Design Goals

### Pre-Terraform Setup (Already Complete)
1. ✅ Tenant Root Management Group (Azure default)
2. ✅ Four Azure Subscriptions (sub-root, sub-hq, sub-sales, sub-service)
3. ✅ Resource Group: `rg-root-iac` (in sub-root subscription)
4. ✅ Key Vault: `kv-root-terraform` (for sensitive values and subscription IDs)
5. ✅ Storage Account: `storerootblob` (for remote state with 6 containers)
6. ✅ Native Key Vault integration via Terraform data sources (see [data-sources.tf](data-sources.tf))

### Module 1: Common (Shared Logic)
**Purpose**: Reusable naming logic, variables, and data sources shared by both foundation and workloads modules

**Location**: `modules/common/`

**Contents**:
- `naming.tf` - CAF naming patterns (resource_type_map, naming_patterns)
- `variables.tf` - Common variable definitions (org_name, environment, location, common_tags)
- `outputs.tf` - Expose naming patterns and variables to parent modules
- `README.md` - Module documentation

**Why Separate?**
- ✅ DRY principle - single source of truth for naming logic
- ✅ Consistency - both foundation and workloads use identical naming patterns
- ✅ Maintainability - update naming logic in one place
- ✅ Testability - can test naming logic independently

### Module 2: Foundation (One-time Setup)
**Purpose**: Organizational structure that rarely changes

**Lifecycle**: Create once, never destroy

**Location**: `modules/foundation/` (module code) and `foundation/` (root caller)

**Resources**:
- Management Groups: `mg-a10corp-hq`, `mg-a10corp-sales`, `mg-a10corp-service`
- Subscription assignments to MGs

**Dependencies**:
- Calls `modules/common` for naming patterns
- Uses Key Vault data sources for subscription IDs

**State File**: `foundation-<env>.tfstate` in Azure Storage

### Module 3: Workloads (Environment-specific)
**Purpose**: Resource Groups per environment

**Lifecycle**: Can be destroyed and recreated safely

**Location**: `modules/workloads/` (module code) and `workloads/` (root caller)

**Resources**:
- Resource Groups per environment:
  - `rg-a10corp-shared-{env}` (in HQ subscription)
  - `rg-a10corp-sales-{env}` (in Sales subscription)
  - `rg-a10corp-service-{env}` (in Service subscription)

**Dependencies**:
- Calls `modules/common` for naming patterns
- Uses Key Vault data sources for subscription IDs
- May reference foundation outputs (optional, for validation)

**State File**: `workloads-<env>.tfstate` in Azure Storage

---

## New Directory Structure

```
terraform_iac/
├── modules/
│   ├── common/                          # Module 1: Shared logic (THE BRAIN)
│   │   ├── naming.tf                    # CAF naming patterns
│   │   ├── variables.tf                 # ALL variables WITH defaults
│   │   ├── data-sources.tf              # Key Vault data sources (fetches subscription IDs)
│   │   ├── outputs.tf                   # Exposes EVERYTHING (naming, variables, subscription IDs)
│   │   └── README.md                    # Module documentation
│   │
│   ├── foundation/                      # Module 2: Management Groups (THIN WRAPPER)
│   │   ├── main.tf                      # Management groups
│   │   ├── subscriptions.tf             # Subscription assignments
│   │   ├── variables.tf                 # Type declarations ONLY (no defaults)
│   │   ├── outputs.tf                   # Output MG IDs
│   │   └── README.md                    # Module documentation
│   │
│   └── workloads/                       # Module 3: Resource Groups (THIN WRAPPER)
│       ├── main.tf                      # Resource groups
│       ├── variables.tf                 # Type declarations ONLY (no defaults)
│       ├── outputs.tf                   # Output RG names/IDs
│       └── README.md                    # Module documentation
│
├── foundation/                          # Foundation root caller (SIMPLE)
│   ├── backend.tf                       # Remote state config (single file: foundation.tfstate)
│   ├── providers.tf                     # Provider config (default only, no aliases)
│   ├── main.tf                          # Calls common + foundation modules
│   ├── outputs.tf                       # Output foundation results
│   └── README.md                        # Foundation deployment docs
│   # NO variables.tf - uses common module defaults
│   # NO data-sources.tf - common module handles it
│   # NO environments/ - foundation is global, not per-environment
│
├── workloads/                           # Workloads root caller (ENVIRONMENT-AWARE)
│   ├── backend.tf                       # Remote state config (per environment)
│   ├── providers.tf                     # Provider config with aliased providers
│   ├── main.tf                          # Calls common + workloads modules
│   ├── variables.tf                     # Minimal - just environment override
│   ├── outputs.tf                       # Output workloads results
│   ├── environments/
│   │   ├── dev.tfvars                   # environment = "dev"
│   │   ├── stage.tfvars                 # environment = "stage"
│   │   └── prod.tfvars                  # environment = "prod"
│   └── README.md                        # Workloads deployment docs
│   # NO data-sources.tf - common module handles it
│
├── .github/workflows/                   # CI/CD workflows
│   ├── foundation-deploy.yml            # Foundation deployment
│   └── workloads-deploy.yml             # Workloads deployment
│
├── scripts/                             # Helper scripts (optional)
│   └── validate-naming.sh               # Test naming patterns
│
└── archive/                             # Legacy monolithic files
    ├── providers.tf
    ├── data-sources.tf
    ├── management-groups.tf
    ├── subscriptions.tf
    ├── resource-groups.tf
    ├── naming.tf
    ├── variables.tf
    └── environments/*.tfvars
```

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

#### Common Variables (Used by Both Modules)
All environment-specific .tfvars files contain the same non-sensitive variables:

```hcl
# foundation/environments/dev.tfvars OR workloads/environments/dev.tfvars
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
}

# Subscription IDs fetched from Key Vault via data sources (not in .tfvars)
```

---

## Module Call Patterns

### Foundation Root Module (foundation/main.tf)
```hcl
# Call common module for naming patterns
module "common" {
  source = "../modules/common"

  org_name    = var.org_name
  environment = var.environment
  location    = var.location
  common_tags = var.common_tags
}

# Call foundation module for management groups
module "foundation" {
  source = "../modules/foundation"

  # Pass naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Pass subscription IDs from Key Vault data sources
  tenant_id               = local.tenant_id
  hq_subscription_id      = local.hq_subscription_id
  sales_subscription_id   = local.sales_subscription_id
  service_subscription_id = local.service_subscription_id

  # Pass other variables
  common_tags = var.common_tags
}
```

### Workloads Root Module (workloads/main.tf)
```hcl
# Call common module for naming patterns
module "common" {
  source = "../modules/common"

  org_name    = var.org_name
  environment = var.environment
  location    = var.location
  common_tags = var.common_tags
}

# Call workloads module for resource groups
module "workloads" {
  source = "../modules/workloads"

  # Pass naming patterns from common module
  naming_patterns = module.common.naming_patterns

  # Pass subscription IDs from Key Vault data sources
  hq_subscription_id      = local.hq_subscription_id
  sales_subscription_id   = local.sales_subscription_id
  service_subscription_id = local.service_subscription_id

  # Pass other variables
  location    = var.location
  common_tags = var.common_tags
}
```

---

## Implementation Steps

### Phase 1: Infrastructure Preparation ✅ COMPLETE
- [x] 1.1. Create Resource Group for Terraform state: `rg-root-iac`
- [x] 1.2. Create Storage Account: `storerootblob`
- [x] 1.3. Create containers: `foundation-dev/stage/prod`, `workloads-dev/stage/prod`
- [x] 1.4. Create Key Vault: `kv-root-terraform`
- [x] 1.5. Configure Key Vault RBAC and upload sensitive secrets
- [x] 1.6. Enable blob versioning and soft delete on storage account

### Phase 2: Create Common Module
- [ ] 2.1. Create directory: `modules/common/`
- [ ] 2.2. Extract naming logic from current `naming.tf` → `modules/common/naming.tf`
- [ ] 2.3. Extract variable definitions from current `variables.tf` → `modules/common/variables.tf`
- [ ] 2.4. Create `modules/common/outputs.tf` to expose:
  - `output "naming_patterns"` - The full naming_patterns map
  - `output "org_name"` - For reference
  - `output "environment"` - For reference
  - `output "location"` - For reference
  - `output "common_tags"` - For reference
- [ ] 2.5. Create `modules/common/README.md` with usage examples
- [ ] 2.6. Test common module independently with `terraform console`

### Phase 3: Create Foundation Module
- [ ] 3.1. Create directory: `modules/foundation/`
- [ ] 3.2. Extract management groups from current `management-groups.tf` → `modules/foundation/main.tf`
  - Update to receive `naming_patterns` as input variable
  - Replace `local.naming_patterns` with `var.naming_patterns`
- [ ] 3.3. Extract subscription assignments from current `subscriptions.tf` → `modules/foundation/subscriptions.tf`
- [ ] 3.4. Create `modules/foundation/variables.tf`:
  - `variable "naming_patterns"` (type = map)
  - `variable "tenant_id"`
  - `variable "hq_subscription_id"`
  - `variable "sales_subscription_id"`
  - `variable "service_subscription_id"`
  - `variable "common_tags"`
- [ ] 3.5. Create `modules/foundation/outputs.tf` to expose MG IDs
- [ ] 3.6. Create `modules/foundation/README.md`

### Phase 4: Create Workloads Module
- [ ] 4.1. Create directory: `modules/workloads/`
- [ ] 4.2. Extract resource groups from current `resource-groups.tf` → `modules/workloads/main.tf`
  - Update to receive `naming_patterns` as input variable
  - Replace `local.naming_patterns` with `var.naming_patterns`
  - Remove provider blocks (will be passed from parent)
- [ ] 4.3. Create `modules/workloads/variables.tf`:
  - `variable "naming_patterns"` (type = map)
  - `variable "hq_subscription_id"`
  - `variable "sales_subscription_id"`
  - `variable "service_subscription_id"`
  - `variable "location"`
  - `variable "common_tags"`
- [ ] 4.4. Create `modules/workloads/outputs.tf` to expose RG names/IDs
- [ ] 4.5. Create `modules/workloads/README.md`

### Phase 5: Create Foundation Root Caller
- [ ] 5.1. Create directory: `foundation/`
- [ ] 5.2. Create `foundation/backend.tf` with Azure Storage backend:
  ```hcl
  terraform {
    backend "azurerm" {
      resource_group_name  = "rg-root-iac"
      storage_account_name = "storerootblob"
      container_name       = "foundation-dev"  # Set per environment
      key                  = "terraform.tfstate"
    }
  }
  ```
- [ ] 5.3. Create `foundation/providers.tf`:
  - Default provider (uses .env or OIDC)
  - Aliased providers (hq, sales, service) using Key Vault data
- [ ] 5.4. Create `foundation/data-sources.tf`:
  - Key Vault data sources for subscription/tenant IDs
  - Locals for convenience (`local.tenant_id`, etc.)
- [ ] 5.5. Create `foundation/main.tf`:
  - Call `modules/common`
  - Call `modules/foundation`
  - Pass naming patterns from common to foundation
- [ ] 5.6. Create `foundation/variables.tf` (minimal - just environment selector)
- [ ] 5.7. Create `foundation/outputs.tf`
- [ ] 5.8. Create `foundation/environments/*.tfvars` (non-sensitive only)
- [ ] 5.9. Create `foundation/README.md`

### Phase 6: Create Workloads Root Caller
- [ ] 6.1. Create directory: `workloads/`
- [ ] 6.2. Create `workloads/backend.tf` with Azure Storage backend:
  ```hcl
  terraform {
    backend "azurerm" {
      resource_group_name  = "rg-root-iac"
      storage_account_name = "storerootblob"
      container_name       = "workloads-dev"  # Set per environment
      key                  = "terraform.tfstate"
    }
  }
  ```
- [ ] 6.3. Create `workloads/providers.tf`:
  - Default provider (uses .env or OIDC)
  - Aliased providers (hq, sales, service) using Key Vault data
- [ ] 6.4. Create `workloads/data-sources.tf`:
  - Key Vault data sources for subscription/tenant IDs
  - Locals for convenience
  - (Optional) Foundation remote state data source
- [ ] 6.5. Create `workloads/main.tf`:
  - Call `modules/common`
  - Call `modules/workloads`
  - Pass naming patterns from common to workloads
- [ ] 6.6. Create `workloads/variables.tf` (minimal)
- [ ] 6.7. Create `workloads/outputs.tf`
- [ ] 6.8. Create `workloads/environments/*.tfvars` (non-sensitive only)
- [ ] 6.9. Create `workloads/README.md`

### Phase 7: Testing & Validation
- [ ] 7.1. Test common module:
  ```bash
  cd modules/common/
  terraform init
  terraform console
  # Verify naming_patterns output
  ```
- [ ] 7.2. Test foundation module locally:
  ```bash
  cd foundation/
  source ../.env
  terraform init
  terraform validate
  terraform plan -var-file="environments/dev.tfvars"
  ```
- [ ] 7.3. Test workloads module locally:
  ```bash
  cd workloads/
  source ../.env
  terraform init
  terraform validate
  terraform plan -var-file="environments/dev.tfvars"
  ```
- [ ] 7.4. Verify naming consistency between modules
- [ ] 7.5. Verify provider authentication works

### Phase 8: State Migration (FROM MONOLITHIC TO MODULAR)
**⚠️ Critical Phase - Backup state files first!**

- [ ] 8.1. Backup current state file:
  ```bash
  cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
  ```
- [ ] 8.2. Initialize foundation module with remote backend:
  ```bash
  cd foundation/
  terraform init
  ```
- [ ] 8.3. Import existing management groups to foundation state:
  ```bash
  # If MGs already exist in Azure (not currently - they were destroyed)
  terraform import module.foundation.azurerm_management_group.a10corp "/providers/Microsoft.Management/managementGroups/mg-a10corp-hq"
  terraform import module.foundation.azurerm_management_group.sales "/providers/Microsoft.Management/managementGroups/mg-a10corp-sales"
  terraform import module.foundation.azurerm_management_group.service "/providers/Microsoft.Management/managementGroups/mg-a10corp-service"
  ```
- [ ] 8.4. Verify foundation state:
  ```bash
  terraform state list
  terraform plan -var-file="environments/dev.tfvars"  # Should show no changes
  ```
- [ ] 8.5. Initialize workloads module with remote backend:
  ```bash
  cd workloads/
  terraform init
  ```
- [ ] 8.6. Import existing resource groups to workloads state (if they exist):
  ```bash
  # If RGs already exist in Azure (not currently - they were destroyed)
  terraform import module.workloads.azurerm_resource_group.shared_common "/subscriptions/{sub-hq-id}/resourceGroups/rg-a10corp-shared-dev"
  terraform import module.workloads.azurerm_resource_group.sales "/subscriptions/{sub-sales-id}/resourceGroups/rg-a10corp-sales-dev"
  terraform import module.workloads.azurerm_resource_group.service "/subscriptions/{sub-service-id}/resourceGroups/rg-a10corp-service-dev"
  ```
- [ ] 8.7. Verify workloads state:
  ```bash
  terraform state list
  terraform plan -var-file="environments/dev.tfvars"  # Should show no changes
  ```
- [ ] 8.8. Archive old monolithic files:
  ```bash
  mkdir -p archive/
  mv providers.tf data-sources.tf management-groups.tf subscriptions.tf resource-groups.tf naming.tf variables.tf outputs.tf archive/
  mv terraform.tfstate* archive/
  ```

### Phase 9: GitHub Actions Workflows (Two Separate Workflows)

**Important**: We need **two independent workflows** - one for foundation, one for workloads. Each operates on its own directory and state.

#### Workflow 1: Foundation Deployment
- [ ] 9.1. Create `.github/workflows/foundation-deploy.yml`:
  - **Working directory**: `foundation/`
  - **OIDC authentication** with Azure (sets ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
  - **Environment selection**: Manual trigger with dev/stage/prod input
  - **Actions**: plan/apply (no destroy - foundation is permanent)
  - **Backend config**: Points to `foundation-{env}` container
  - **Terraform commands**:
    ```bash
    cd foundation/
    terraform init
    terraform plan -var-file="environments/${environment}.tfvars"
    terraform apply -var-file="environments/${environment}.tfvars"
    ```

#### Workflow 2: Workloads Deployment
- [ ] 9.2. Create `.github/workflows/workloads-deploy.yml`:
  - **Working directory**: `workloads/`
  - **OIDC authentication** with Azure (sets ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
  - **Environment selection**: Manual trigger with dev/stage/prod input
  - **Actions**: plan/apply/destroy (workloads can be destroyed)
  - **Backend config**: Points to `workloads-{env}` container
  - **Terraform commands**:
    ```bash
    cd workloads/
    terraform init
    terraform plan -var-file="environments/${environment}.tfvars"
    terraform apply -var-file="environments/${environment}.tfvars"
    # OR
    terraform destroy -var-file="environments/${environment}.tfvars"
    ```

- [ ] 9.3. Test foundation workflow on dev environment
- [ ] 9.4. Test workloads workflow on dev environment
- [ ] 9.5. Archive old `terraform-deploy.yml`

### Phase 10: Documentation
- [ ] 10.1. Update `CLAUDE.md` with three-module structure
- [ ] 10.2. Update `DECISIONS.md` with Decision 15 (Three-module architecture)
- [ ] 10.3. Update `TERRAFORM_COMMANDS.md` with new workflows
- [ ] 10.4. Create architecture diagram (optional)
- [ ] 10.5. Create team onboarding guide

### Phase 11: Deployment & Rollout
- [ ] 11.1. Deploy foundation to dev:
  ```bash
  cd foundation/
  terraform apply -var-file="environments/dev.tfvars"
  ```
- [ ] 11.2. Deploy workloads to dev:
  ```bash
  cd workloads/
  terraform apply -var-file="environments/dev.tfvars"
  ```
- [ ] 11.3. Verify dev environment is healthy
- [ ] 11.4. Deploy foundation to stage
- [ ] 11.5. Deploy workloads to stage
- [ ] 11.6. Deploy foundation to prod
- [ ] 11.7. Deploy workloads to prod
- [ ] 11.8. Commit all changes to git:
  ```bash
  git add .
  git commit -m "Refactor: Implement three-module architecture (common, foundation, workloads)"
  git push origin main
  ```

---

## Local Development Workflow (After Migration)

### Prerequisites
```bash
# 1. Authenticate with Azure
az login

# 2. Load environment variables (sets ARM_SUBSCRIPTION_ID and ARM_TENANT_ID for default provider)
source .env
```

### Deploy Foundation (One-time per environment)
```bash
cd foundation/
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

**How it works:**
- Default provider uses `.env` file (ARM_SUBSCRIPTION_ID = sub-root)
- Calls `modules/common` for naming patterns
- Calls `modules/foundation` for management groups
- Data sources fetch subscription IDs from Key Vault
- Aliased providers (hq, sales, service) use fetched subscription IDs

### Deploy Workloads (Repeatable)
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

### Test Naming Patterns (from common module)
```bash
cd modules/common/
terraform console
# Try: local.naming_patterns["azurerm_resource_group"]["sales"]
# Expected: "rg-a10corp-sales-dev"
```

---

## GitHub Actions Workflow (After Migration)

### Foundation Deployment
1. Navigate to: Actions → Deploy Foundation
2. Select environment: dev/stage/prod
3. Select action: plan/apply
4. Workflow authenticates with Azure via OIDC
5. Runs terraform in `foundation/` directory
6. Uses `foundation/environments/{env}.tfvars`

### Workloads Deployment
1. Navigate to: Actions → Deploy Workloads
2. Select environment: dev/stage/prod
3. Select action: plan/apply/destroy
4. Workflow authenticates with Azure via OIDC
5. Runs terraform in `workloads/` directory
6. Uses `workloads/environments/{env}.tfvars`

---

## Rollback Plan

If migration fails:
1. Restore backup of `terraform.tfstate`
2. Restore archived monolithic files from `archive/`
3. Run `terraform init` in root directory
4. Run `terraform plan` to verify state
5. Document issues encountered
6. Review DECISIONS.md before next attempt

---

## Success Criteria

✅ Common module can be independently tested with `terraform console`
✅ Foundation module deploys successfully with shared naming patterns
✅ Workloads module deploys successfully with shared naming patterns
✅ Both modules produce consistent naming (verified with outputs)
✅ Can destroy/recreate workloads without affecting foundation
✅ GitHub Actions workflows execute successfully for both modules
✅ Local development workflow functions correctly
✅ All documentation updated
✅ State files properly separated in Azure Storage
✅ No duplication of naming logic between modules

---

## Benefits of Three-Module Approach

### Compared to Two-Module Architecture

**Original Two-Module Issues:**
- ❌ Naming logic duplicated in foundation and workloads
- ❌ Variables duplicated in foundation and workloads
- ❌ Naming pattern drift risk (foundation and workloads could diverge)
- ❌ Harder to test naming logic independently

**Three-Module Benefits:**
1. **DRY Principle**: Single source of truth for naming patterns
2. **Consistency**: Impossible for foundation and workloads to have different naming schemes
3. **Testability**: Can test naming patterns independently without deploying infrastructure
4. **Separation of Concerns**:
   - Common = reusable logic
   - Foundation = stable organizational structure
   - Workloads = dynamic environment-specific resources
5. **Maintainability**: Update naming rules in one place, both modules benefit
6. **Scalability**: Easy to add new modules (e.g., networking) that reuse common logic
7. **Team Collaboration**: Clear ownership boundaries (common = platform team, workloads = app teams)

---

## Key Design Decisions

### Why Three Modules Instead of Two?

**Problem**: Naming logic is needed by both foundation and workloads modules.

**Options Considered**:
1. **Duplicate naming logic** in both modules → ❌ Violates DRY, drift risk
2. **Foundation outputs naming patterns** for workloads → ❌ Creates unnecessary dependency
3. **Separate common module** (chosen) → ✅ Clean, reusable, testable

**Decision**: Create a third module (`modules/common/`) that contains shared logic and is called by both foundation and workloads.

### Module Dependencies

```
foundation/              workloads/
    ↓                        ↓
    ↓                        ↓
    └─────→ modules/common ←─┘

(No dependency between foundation and workloads)
```

This creates a clean architecture where:
- Foundation and workloads are **independent** (can deploy in any order)
- Both depend on common (but common has no dependencies)
- Naming patterns are guaranteed consistent across all infrastructure

---

**Last Updated**: 2025-12-17
**Status**: Infrastructure Ready - Three-Module Architecture Planned
**Next Action**: Begin Phase 2 (Create Common Module)
