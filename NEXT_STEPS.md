# Next Steps: Two-Module Refactoring

This document outlines the plan to refactor the current Terraform code into a two-module architecture.

## Current State

**Deployed Resources (Dev Environment):**
- Management Groups: `mg-a10corp-hq`, `mg-a10corp-sales`, `mg-a10corp-service`
- Resource Groups: `rg-a10corp-shared-dev`, `rg-a10corp-sales-dev`, `rg-a10corp-service-dev`
- Subscription Associations: All subscriptions assigned to their respective MGs

**Issue**: Current monolithic structure makes it risky to destroy/recreate resource groups without affecting management groups.

---

## Design Goals

### Pre-Terraform Setup (Already Exists)
1. ✅ Tenant Root Management Group (Azure default)
2. ✅ Tenant Root Subscription (root subscription)
3. ✅ Sales Subscription (manually created)
4. ✅ Service Subscription (manually created)
5. ⏳ Resource Group under Tenant Root: `rg-a10corp-tfstate-<env>` **[TO BE CREATED]**
   - Key Vault: `kv-a10corp-terraform` (for sensitive .tfvars)
   - Storage Account: `sta10corptfstate` (for remote state with containers: dev, stage, prod)

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
terraform/
├── foundation/                          # Module 1 root
│   ├── backend.tf                       # Remote state config
│   ├── providers.tf                     # Provider config
│   ├── main.tf                          # Calls foundation module
│   ├── environments/
│   │   ├── dev.tfvars                   # Non-sensitive (in repo)
│   │   ├── stage.tfvars                 # Non-sensitive (in repo)
│   │   └── prod.tfvars                  # Non-sensitive (in repo)
│   └── README.md                        # Module 1 docs
│
├── workloads/                           # Module 2 root
│   ├── backend.tf                       # Remote state config
│   ├── providers.tf                     # Provider config
│   ├── main.tf                          # Calls workloads module
│   ├── data.tf                          # Data sources (references foundation outputs)
│   ├── environments/
│   │   ├── dev.tfvars                   # Non-sensitive (in repo)
│   │   ├── stage.tfvars                 # Non-sensitive (in repo)
│   │   └── prod.tfvars                  # Non-sensitive (in repo)
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
├── scripts/
│   ├── fetch-sensitive-tfvars.sh        # Fetch from Key Vault
│   ├── upload-sensitive-tfvars.sh       # Upload to Key Vault
│   ├── init-foundation.sh               # Initialize foundation module
│   └── init-workloads.sh                # Initialize workloads module
│
└── secure/                              # Gitignored
    ├── foundation/
    │   ├── dev-sensitive.tfvars
    │   ├── stage-sensitive.tfvars
    │   └── prod-sensitive.tfvars
    └── workloads/
        ├── dev-sensitive.tfvars
        ├── stage-sensitive.tfvars
        └── prod-sensitive.tfvars
```

---

## .tfvars Split Strategy

### Foundation Module

#### Non-Sensitive (in repo) - `foundation/environments/dev.tfvars`
```hcl
org_name    = "a10corp"
environment = "dev"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
  Module      = "Foundation"
}
```

#### Sensitive (Key Vault) - Secret: `tfvars-foundation-dev-sensitive`
```hcl
tenant_id               = "8116fad0-5032-463e-b911-cc6d1d75001d"
root_subscription_id    = "fdb297a9-2ece-469c-808d-a8227259f6e8"
sales_subscription_id   = "385c6fcb-c70b-4aed-b745-76bd608303d7"
service_subscription_id = "aef7255d-42b5-4f84-81f2-202191e8c7d1"
```

### Workloads Module

#### Non-Sensitive (in repo) - `workloads/environments/dev.tfvars`
```hcl
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
  Module      = "Workloads"
}
```

#### Sensitive (Key Vault) - Secret: `tfvars-workloads-dev-sensitive`
```hcl
root_subscription_id    = "fdb297a9-2ece-469c-808d-a8227259f6e8"
sales_subscription_id   = "385c6fcb-c70b-4aed-b745-76bd608303d7"
service_subscription_id = "aef7255d-42b5-4f84-81f2-202191e8c7d1"
```

---

## Implementation Steps

### Phase 1: Infrastructure Preparation
- [ ] 1.1. Create Resource Group for Terraform state: `rg-a10corp-tfstate-dev`
- [ ] 1.2. Create Storage Account: `sta10corptfstate`
- [ ] 1.3. Create containers: `dev`, `stage`, `prod`
- [ ] 1.4. Create Key Vault: `kv-a10corp-terraform`
- [ ] 1.5. Grant GitHub service principal access to Key Vault

### Phase 2: Code Refactoring
- [ ] 2.1. Create module directories (`modules/foundation/`, `modules/workloads/`)
- [ ] 2.2. Create root directories (`foundation/`, `workloads/`)
- [ ] 2.3. Split `management-groups.tf` and `subscriptions.tf` → `modules/foundation/`
- [ ] 2.4. Split `resource-groups.tf` → `modules/workloads/`
- [ ] 2.5. Split `naming.tf` into module-specific naming logic
- [ ] 2.6. Create `foundation/main.tf` that calls foundation module
- [ ] 2.7. Create `workloads/main.tf` that calls workloads module
- [ ] 2.8. Create `workloads/data.tf` to reference foundation outputs (if needed)

### Phase 3: Variables Split
- [ ] 3.1. Create non-sensitive .tfvars in `foundation/environments/`
- [ ] 3.2. Create non-sensitive .tfvars in `workloads/environments/`
- [ ] 3.3. Create sensitive .tfvars templates in `secure/foundation/`
- [ ] 3.4. Create sensitive .tfvars templates in `secure/workloads/`
- [ ] 3.5. Update variables.tf for each module

### Phase 4: Backend Configuration
- [ ] 4.1. Create `foundation/backend.tf` with Azure Storage backend
- [ ] 4.2. Create `workloads/backend.tf` with Azure Storage backend
- [ ] 4.3. Configure separate state files for each module

### Phase 5: Scripts & Automation
- [ ] 5.1. Create `scripts/fetch-sensitive-tfvars.sh`
- [ ] 5.2. Create `scripts/upload-sensitive-tfvars.sh`
- [ ] 5.3. Create `scripts/init-foundation.sh`
- [ ] 5.4. Create `scripts/init-workloads.sh`
- [ ] 5.5. Make scripts executable (`chmod +x scripts/*.sh`)

### Phase 6: Key Vault Setup
- [ ] 6.1. Upload foundation sensitive .tfvars to Key Vault
  - `tfvars-foundation-dev-sensitive`
  - `tfvars-foundation-stage-sensitive`
  - `tfvars-foundation-prod-sensitive`
- [ ] 6.2. Upload workloads sensitive .tfvars to Key Vault
  - `tfvars-workloads-dev-sensitive`
  - `tfvars-workloads-stage-sensitive`
  - `tfvars-workloads-prod-sensitive`

### Phase 7: GitHub Actions Workflows
- [ ] 7.1. Create `.github/workflows/foundation-deploy.yml`
- [ ] 7.2. Create `.github/workflows/workloads-deploy.yml`
- [ ] 7.3. Update workflows to fetch sensitive .tfvars from Key Vault
- [ ] 7.4. Remove old `terraform-deploy.yml` workflow

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

### Fetch Sensitive Values
```bash
# Fetch sensitive tfvars for both modules
./scripts/fetch-sensitive-tfvars.sh foundation dev
./scripts/fetch-sensitive-tfvars.sh workloads dev
```

### Apply Foundation (One-time)
```bash
cd foundation/
terraform init
terraform plan \
  -var-file="environments/dev.tfvars" \
  -var-file="../secure/foundation/dev-sensitive.tfvars"
terraform apply \
  -var-file="environments/dev.tfvars" \
  -var-file="../secure/foundation/dev-sensitive.tfvars"
```

### Apply Workloads (Repeatable)
```bash
cd workloads/
terraform init
terraform plan \
  -var-file="environments/dev.tfvars" \
  -var-file="../secure/workloads/dev-sensitive.tfvars"
terraform apply \
  -var-file="environments/dev.tfvars" \
  -var-file="../secure/workloads/dev-sensitive.tfvars"
```

---

## GitHub Actions Workflow (After Migration)

### Foundation Deployment
1. Navigate to: Actions → Deploy Foundation
2. Select environment: dev/stage/prod
3. Select action: plan/apply
4. Workflow fetches sensitive .tfvars from Key Vault
5. Runs terraform plan/apply

### Workloads Deployment
1. Navigate to: Actions → Deploy Workloads
2. Select environment: dev/stage/prod
3. Select action: plan/apply/destroy
4. Workflow fetches sensitive .tfvars from Key Vault
5. Runs terraform plan/apply/destroy

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

**Last Updated**: 2025-12-16
**Status**: Planning Phase
