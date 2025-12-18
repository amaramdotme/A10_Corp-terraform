# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Terraform infrastructure-as-code for setting up Azure Management Groups, Resource Groups, and associated resources in the A10 Corporation Azure environment.

**Repository**: Private GitHub repo at `github.com:GoldenSapien/A10_Corp-terraform.git`

**Key Features:**
- Multi-environment support (dev, stage, prod) using `.tfvars` files
- Azure CAF-compliant naming via Terraform locals
- Hierarchical Management Group structure
- Terraform state management for infrastructure tracking
- OIDC-based authentication for GitHub Actions (no long-lived secrets)

## Quick Reference

- **Architecture Details**: See [azure.md](azure.md)
- **Design Decisions**: See [DECISIONS.md](DECISIONS.md) for architectural choices and trade-offs
- **Terraform Commands**: See [TERRAFORM_COMMANDS.md](TERRAFORM_COMMANDS.md) for comprehensive command reference
- **OIDC Setup Guide**: See [secure/OIDC_SETUP.md](secure/OIDC_SETUP.md) for GitHub Actions authentication setup

**Note**: The `secure/` directory is gitignored and contains sensitive planning documents and credentials. Never commit this directory.

## Architecture Summary

### Management Group Hierarchy
```
Tenant Root Group
└── mg-a10corp-hq
    ├── mg-a10corp-sales (with dedicated subscription)
    └── mg-a10corp-service (with dedicated subscription)
```
*Note: Subscription IDs are stored in `environments/*.tfvars` files (gitignored) and injected via GitHub Secrets in CI/CD.*

### Naming Convention
- Management Groups: `mg-{org}-{workload}` (e.g., `mg-a10corp-sales`)
- Resource Groups: `rg-{org}-{workload}-{environment}` (e.g., `rg-a10corp-sales-dev`)

See [DECISIONS.md](DECISIONS.md) for why these patterns were chosen.

## Common Workflows

**Important**: All terraform commands must be run from the **repository root directory**. Terraform binary is located at `~/bin/terraform`.

### First-Time Setup

```bash
# 1. Verify you're in the repository root
pwd  # Should show: .../terraform_iac

# 2. Create .env file from example (first time only)
cp .env.example .env
# Edit .env with your Azure subscription/tenant IDs (or use `az account show` to get current values)

# 3. Authenticate with Azure
az login

# 4. Load environment variables
source .env

# 5. Initialize Terraform
terraform init
terraform validate

# 6. Test the configuration
terraform plan -var-file="environments/dev.tfvars"
```

### Daily Development Workflow

```bash
# 1. Authenticate with Azure (if not already logged in)
az login

# 2. Load environment variables
source .env

# 3. Run Terraform commands
terraform fmt -recursive
terraform validate
terraform plan -var-file="environments/dev.tfvars" -out=tfplan
terraform apply tfplan
```

### Multi-Environment Deployment

```bash
# Always source .env first
source .env

# Development
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan

# Staging
terraform plan -var-file="environments/stage.tfvars" -out=stage.tfplan
terraform apply stage.tfplan

# Production
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

**See [TERRAFORM_COMMANDS.md](TERRAFORM_COMMANDS.md) for complete command reference.**

## Prerequisites

- Terraform >= 1.0 installed (`~/bin/terraform`)
- Azure CLI authenticated (`az login`)
- Required Azure permissions:
  - Management Group Contributor (for management groups)
  - Owner/Contributor on subscriptions (for resource groups)

## Current File Structure (Monolithic - Before Restructure)

```
terraform_iac/           # Repository root (run terraform here)
├── providers.tf          # Provider configuration (default + aliased providers)
├── variables.tf          # Variable declarations (with sensible defaults)
├── data-sources.tf       # Key Vault data sources for sensitive values
├── naming.tf            # Centralized CAF naming logic using pure Terraform locals
├── management-groups.tf # Management group hierarchy
├── subscriptions.tf     # Subscription associations
├── resource-groups.tf   # Resource group definitions
├── imports.tf           # Import blocks for existing resources
├── outputs.tf           # Output values
├── environments/        # Environment-specific variables (safe for git)
│   ├── dev.tfvars       # ✅ Just: environment = "dev"
│   ├── stage.tfvars     # ✅ Just: environment = "stage"
│   └── prod.tfvars      # ✅ Just: environment = "prod"
├── .env                 # Local dev environment variables (gitignored)
├── .env.example         # Template for .env file (committed)
├── .github/workflows/   # GitHub Actions CI/CD
└── DECISIONS.md         # Architectural decisions log
```

**✅ Key Vault Integration**: Subscription and tenant IDs are fetched from Azure Key Vault at runtime (see [DECISIONS.md](DECISIONS.md) Decision 14).

**⚠️ Important**: Current structure is monolithic and pending restructure into two-module architecture (see "Next Steps" section below).

### Target File Structure (Two-Module Architecture - After Restructure)

See [DECISIONS.md](DECISIONS.md#decision-11-module-separation-strategy) for the planned two-module architecture. The target structure will be:

```
terraform_iac/
├── foundation/          # Module 1: Management Groups (rarely changed)
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   └── environments/
├── workloads/           # Module 2: Resource Groups (frequently changed)
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   └── environments/
├── modules/             # Shared module code
│   ├── foundation/
│   └── workloads/
├── scripts/             # Helper scripts for Key Vault operations
└── secure/              # Gitignored - local sensitive .tfvars
```

### Naming Architecture ([naming.tf](naming.tf))

**Critical**: All resource naming is centralized in [naming.tf](naming.tf:1-90) using pure Terraform locals (no external providers).

**How it works:**
1. **Resource Type Map**: `local.resource_type_map` defines CAF prefixes (rg, mg, vm, pg, etc.)
2. **Environment Rules**: `local.resource_include_env` controls whether resource type includes environment suffix
   - `true` → `{prefix}-{org}-{workload}-{env}` (e.g., "rg-a10corp-sales-dev")
   - `false` → `{prefix}-{org}-{workload}` (e.g., "mg-a10corp-sales")
3. **Naming Patterns**: `local.naming_patterns[resource_type][workload]` provides the final name
4. **Validation**: `null_resource.validate_caf_naming` ensures config consistency

**Usage in resource files:**
```hcl
resource "azurerm_resource_group" "sales" {
  name     = local.naming_patterns["azurerm_resource_group"]["sales"]
  location = var.location
}
```

**Adding new resource types:**
1. Add to `resource_type_map` with CAF prefix
2. Add to `resource_include_env` with true/false rule
3. Validation will fail if maps are inconsistent (fail-fast design)

### Key Vault Integration ([data-sources.tf](data-sources.tf))

**Native Terraform Approach**: Sensitive values (subscription/tenant IDs) are fetched directly from Azure Key Vault using Terraform data sources.

**How it works:**
1. **Default Provider Authentication**: Uses `.env` file (local) or GitHub Actions OIDC (CI/CD)
2. **Key Vault Data Sources**: Terraform fetches 4 secrets per environment from Key Vault
3. **Locals for Convenience**: Secrets exposed via `local.tenant_id`, `local.hq_subscription_id`, etc.
4. **Aliased Providers**: HQ, Sales, Service providers use the fetched subscription IDs

**Key Vault Structure:**
```
kv-root-terraform/
├── terraform-dev-tenant-id
├── terraform-dev-hq-sub-id
├── terraform-dev-sales-sub-id
├── terraform-dev-service-sub-id
├── terraform-stage-* (same pattern)
└── terraform-prod-* (same pattern)
```

**Local Development (.env file):**
```bash
# .env (gitignored - for local development)
export ARM_SUBSCRIPTION_ID="fdb297a9-2ece-469c-808d-a8227259f6e8"  # sub-root
export ARM_TENANT_ID="8116fad0-5032-463e-b911-cc6d1d75001d"
```

**GitHub Actions (automatic):**
```yaml
- name: Azure Login via OIDC
  uses: azure/login@v1
  with:
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}  # Sets ARM_SUBSCRIPTION_ID
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}              # Sets ARM_TENANT_ID
```

**Benefits:**
- No circular dependency (default provider uses .env/OIDC, aliased providers use Key Vault)
- Zero secrets in git repository
- Simplified workflow (just `source .env && terraform plan`)
- Audit trail via Key Vault access logs

See [DECISIONS.md](DECISIONS.md) Decision 14 for full rationale.

## Current State (as of 2025-12-17)

### ✅ Infrastructure Status: THREE-MODULE ARCHITECTURE DEPLOYED

**Terraform-Managed Resources**: 7 resources deployed in foundation module

**Pre-Terraform Infrastructure (Manual Setup - Complete):**
- ✅ **Resource Group**: `rg-root-iac` in sub-root subscription
- ✅ **Key Vault**: `kv-root-terraform` (actual deployed name; documentation may reference `kv-a10corp-terraform`)
  - Public network access: Enabled
  - RBAC: User assigned "Key Vault Secrets Officer" role at RG level
  - Secrets: `terraform-dev-sensitive`, `terraform-stage-sensitive`, `terraform-prod-sensitive`
- ✅ **Storage Account**: `storerootblob` (actual deployed name; documentation may reference `sta10corptfstate`)
  - SKU: Standard_LRS
  - Blob versioning: Enabled
  - Soft delete: Enabled (7 days)
  - Containers: `foundation-dev`, `foundation-stage`, `foundation-prod`, `workloads-dev`, `workloads-stage`, `workloads-prod`

**Azure Subscriptions (4 total):**
- sub-root: [ID stored in Key Vault] - Root subscription (stays in Tenant Root MG, never moved)
- sub-hq: [ID stored in Key Vault] - HQ subscription ✅ **ASSOCIATED to mg-a10corp-hq**
- sub-sales: [ID stored in Key Vault] - Sales subscription ✅ **ASSOCIATED to mg-a10corp-sales**
- sub-service: [ID stored in Key Vault] - Service subscription ✅ **ASSOCIATED to mg-a10corp-service**

**✅ Security Note**: Subscription IDs are stored in Key Vault and fetched via data sources. Only non-sensitive environment variables in .tfvars files.

**Repository Status:**
- ✅ Git repository initialized and connected
- ✅ Code committed and pushed to GitHub
- ✅ Repository: `github.com:amaramdotme/A10_Corp-terraform.git` (private)

### ✅ Architecture Complete - Ready for Workloads

**Three-module architecture successfully implemented and deployed:**
1. ✅ Created new directory structure (modules/common, modules/foundation, modules/workloads, foundation/, workloads/)
2. ✅ Split monolithic .tf files into three modules (archived in archive_monolithic/)
3. ✅ Created non-sensitive .tfvars files (only contain environment names)
4. ✅ Configured remote state backends (foundation and workloads)
5. ✅ Implemented Key Vault data sources for sensitive values
6. ✅ Updated .gitignore to protect sensitive files
7. ✅ Foundation module deployed and tested (7 resources)
8. ⏳ **NEXT**: Deploy workloads module (Resource Groups)
9. ✅ Git repository initialized and pushed to GitHub

**Current Deployment:**
- Foundation: 3 Management Groups + 3 Subscription Associations deployed
- Workloads: Not yet deployed (next step)

### 📝 Recent Session Changes (2025-12-17 - Current Session):
1. **Three-Module Architecture Implemented**: Restructured from monolithic to modules/common, modules/foundation, modules/workloads
2. **Missing variables.tf Files Created**:
   - foundation/variables.tf (org_name, location, common_tags)
   - modules/foundation/variables.tf (naming_patterns, subscription IDs, tenant_id, tags)
3. **Storage Account Naming Added**:
   - Added azurerm_storage_account to resource_type_map with "st" prefix
   - Implemented three-branch naming system with no_hyphen_resources set
   - Naming logic: sta10corpsalesdev (alphanumeric only, no hyphens)
4. **Foundation Module Deployed**: Successfully deployed 7 resources (3 MGs + 3 associations + 1 validation)
5. **Remote State Configured**:
   - Foundation using storerootblob/foundation-dev/terraform.tfstate
   - Backend versioning enabled for state history
6. **Git Repository Management**:
   - Committed restructuring changes (59 files, 3042 insertions, 429 deletions)
   - Pushed to github.com:amaramdotme/A10_Corp-terraform.git
   - Commit: 4637c4d "Restructure: Migrate from monolithic to three-module architecture"
7. **Documentation**: Created terraform_commands.txt with complete lifecycle commands for foundation and workloads

### 📝 Previous Session Changes (2025-12-15/16):
1. **Naming System Refactored**: Removed azurecaf provider, now using pure Terraform locals in naming.tf
2. **GitHub Repository Setup**: Created private repository at `github.com:GoldenSapien/A10_Corp-terraform.git`
3. **Documentation Updated**: Updated DECISIONS.md with azurecaf removal rationale and OIDC/CI-CD decisions (Decision 9 & 10)
4. **Security Hardening**: Removed sensitive IDs from azure.md, configured `.gitignore` to exclude `secure/` folder
5. **Outputs Enhanced**: Updated outputs.tf to include comprehensive infrastructure_summary output
6. **GitHub CLI**: Installed and authenticated with SSH + PAT for repository management
7. **Repository Visibility**: Changed from public to private for security
8. **GitHub Actions Workflow**: Created `.github/workflows/terraform-deploy.yml` for CI/CD (not yet tested)

### 📍 Management Groups & Subscriptions (Deployed):

**Management Group Hierarchy:**
```
Tenant Root Group
└── mg-a10corp-hq (a56fd357-2ecc-46bf-b831-1b86e5fd43bb)
    ├── sub-hq associated
    ├── mg-a10corp-sales (3ad4b4c9-368c-44c9-8f02-df14e0da8447)
    │   └── sub-sales associated
    └── mg-a10corp-service (4b511fa7-48ad-495e-b7d7-bf6cfdc8a22e)
        └── sub-service associated
```

**Subscriptions (4 Total):**
- **sub-root**: Root subscription (stays in Tenant Root MG, hosts Key Vault & Storage)
- **sub-hq**: HQ subscription ✅ Associated to mg-a10corp-hq
- **sub-sales**: Sales subscription ✅ Associated to mg-a10corp-sales
- **sub-service**: Service subscription ✅ Associated to mg-a10corp-service

## Session Maintenance Notes

**For future Claude instances:**
1. **Verify current state first**: Run `terraform state list` to see what's actually deployed
2. **Check for drift**: Run `terraform plan -var-file="environments/dev.tfvars"` to see if state matches code
3. Review [DECISIONS.md](DECISIONS.md) before making architectural changes
4. Use environment-specific `.tfvars` files for all deployments
5. Update this file before ending sessions with current deployment status
6. Reference [TERRAFORM_COMMANDS.md](TERRAFORM_COMMANDS.md) for command syntax

## Exit Routine

**Command to invoke:** `>>exit` or "prepare session handoff"

When ending a session, Claude should:
1. Review all changes made during the session
2. Update [CLAUDE.md](CLAUDE.md) "Current State" section with latest deployment status
3. Update [DECISIONS.md](DECISIONS.md) if any new architectural decisions were made
4. Update [azure.md](azure.md) if infrastructure changed
5. Create a session summary including:
   - What was accomplished
   - What's pending
   - Any blockers or issues
   - Next recommended steps
6. Ensure all terraform state is clean (`terraform plan` shows no unexpected changes)

## Troubleshooting

- **"Provider not found" errors**: Run `terraform init -upgrade`
- **"Subscription not found" errors**: Run `az account list --refresh`
- **Resource provider timeout**: Already configured with `resource_provider_registrations = "none"`
- **State lock errors**: Check for stuck locks with `terraform force-unlock`
- **Naming validation errors**: Ensure both `resource_type_map` and `resource_include_env` are updated when adding new resource types
- **Environment mismatch**: Always verify which environment you're targeting with `-var-file` parameter

See [DECISIONS.md](DECISIONS.md) for context on configuration choices.

## Common Pitfalls to Avoid

1. **Don't forget -var-file**: Running `terraform plan` without `-var-file="environments/dev.tfvars"` will fail (variables have no defaults)
2. **Don't manually edit naming in resource files**: All naming logic must go through [naming.tf](naming.tf) to maintain consistency
3. **Don't commit sensitive IDs**: Subscription/tenant IDs belong in Key Vault, not in git repository
   - ⚠️ **Current Issue**: `.gitignore` has sensitive patterns commented out (lines 12-18)
   - ⚠️ **Current Issue**: `environments/*.tfvars` files contain actual subscription IDs that should be in Key Vault
4. **Don't skip state verification**: Always run `terraform state list` before making changes to understand current state
5. **Don't mix environments**: Each environment should have isolated state files (local or separate backends)
6. **Don't run commands from wrong directory**: Must be in repository root, not a subdirectory
