# A10 Corp Terraform User Manual

Last updated: 2025-12-20

This guide explains how to operate, extend, and safely use this repository to manage A10 Corp’s Azure infrastructure with Terraform.

- Source repo: `terraform_iac/`
- Architecture overview: `ARCHITECTURE.md`
- Decisions log: `DECISIONS.md`
- OIDC setup: `OIDC_SETUP.md`
- Resource List: `secure/AZURE_RESOURCES.md`

---

## Audience & Scope

- Cloud engineers and platform teams deploying foundation and workload resources.
- Developers contributing Terraform modules and pipelines.
- Reviewers approving deployments via GitHub Environments.

---

## Quick Start (TL;DR)

1) **Authenticate to Azure locally**:
   - `az login`
   - Ensure `.env` exists (copy from `.env.example`) and run `source .env`.
2) **Deploy Foundation** (global, run once):
   - `./init-plan-apply.sh --foundation init`
   - `./init-plan-apply.sh --foundation plan`
   - `./init-plan-apply.sh --foundation apply`
3) **Deploy Workloads** (per environment):
   - `./init-plan-apply.sh --workloads --env dev init`
   - `./init-plan-apply.sh --workloads --env dev plan`
   - `./init-plan-apply.sh --workloads --env dev apply`
4) **Prefer CI/CD for changes**:
   - Open PR → GitHub Actions generates plans → Approve environment → Apply runs.

---

## 1) Foundations & Workloads Duality

The repo separates “permanent” organizational structure from “replaceable” environment resources.

- **Common library** (`modules/common`)
  - The "brain" of the project.
  - Exposes `naming_patterns`, subscription IDs, and shared variables.
- **Foundation** (one-time, global)
  - Creates management groups and associates subscriptions.
  - Deploys the Global Azure Container Registry (`acra10corpsales`).
  - Never destroy during normal operations.
- **Workloads** (per-environment, safe to destroy/recreate)
  - Creates environment-specific resource groups in the right subscriptions (hq/sales/service).
  - Deploys networking (VNets, Subnets) and identities (Managed Identities).

---

## 2) Operating Model

### Branching & CI/CD
- **PR to `main`**: Triggers plan jobs; comments plan summaries on PR.
- **Push to `main`**: Triggers plan, then apply (requires manual approval for `global` and `prod`).
- **Workflows**: Located in `.github/workflows/`. Includes deploy, destroy, and OIDC test workflows.

### Environments
- **GitHub Environments**: `global`, `workloads-dev`, `workloads-stage`, `workloads-prod`.
- **Foundation** targets `global`. **Workloads** target the specific environment.

### State & Backends
- **Azure Storage**: `storerootblob`.
- **Containers**: `foundation`, `workloads-dev`, `workloads-stage`, `workloads-prod`.
- **OIDC**: GitHub uses OIDC for passwordless authentication. See `OIDC_SETUP.md`.

---

## 3) Governance

### RBAC (Minimum set for CI/CD principal)
- **Contributor** on all 4 subscriptions (root/hq/sales/service).
- **Management Group Contributor** at tenant root.
- **User Access Administrator** on workload subscriptions.
- **Key Vault Secrets User** on `kv-root-terraform`.
- **Storage Blob Data Contributor** on `storerootblob`.

### Naming Standards (CAF)
- Implemented centrally in `modules/common/naming.tf`.
- Follows a three-branch logic to handle Azure resource name restrictions (hyphens vs. no-hyphens).

### Secrets
- No secrets in Git.
- Subscription IDs are fetched at runtime from Key Vault.
- Local `.env` file is gitignored but essential for CLI operations.

---

## 4) Start of Dev User Favorites (Do Not Tamper)
**This section contains critical workflow preferences and architectural patterns that must be preserved by all AI assistants and automated tools.**

================================================================================
TERRAFORM COMMANDS - THREE-MODULE ARCHITECTURE
================================================================================

###### QUICK START HERE ######

###### FOUNDATION STARTS ######
--- Init ---
cd foundation/
source ../.env && terraform init -backend-config="environments/backend.hcl"

#remove backend.tf to store locally
source ../.env && terraform init 

--- Plan & Apply ---
terraform fmt -recursive && terraform validate

terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan

--- State ---
terraform state list
terraform state show module.foundation.azurerm_management_group.hq
terraform state pull > backup-foundation-$(date +%Y%m%d).json

--- Import ---
terraform import \
  module.foundation.azurerm_management_group.hq \
  /providers/Microsoft.Management/managementGroups/mg-a10corp-hq

--- Outputs ---
terraform output
terraform output -json > foundation-outputs.json


--- Destroy ---
source ../.env && terraform destroy 

###### FOUNDATION ENDS ######

###### WORKLOADS STARTS ######

--- Init ---
cd workloads
source ../.env && terraform init -backend-config="environments/backend-dev.hcl"

--- Plan & Apply ---
terraform fmt -recursive && terraform validate

terraform plan -var-file="environments/dev.tfvars" -out=workloads.tfplan

terraform apply "workloads.tfplan"

--- State ---
terraform state list
terraform state show module.workloads.azurerm_resource_group.shared_common
terraform state show module.workloads.azurerm_resource_group.sales
terraform state show module.workloads.azurerm_resource_group.service
terraform state pull > backup-workloads-$(date +%Y%m%d).json

--- Import ---
# Import shared/common resource group (HQ subscription)
terraform import \
  module.workloads.azurerm_resource_group.shared_common \
  /subscriptions/<HQ_SUB_ID>/resourceGroups/rg-a10corp-shared-dev

# Import sales resource group (Sales subscription)
terraform import \
  module.workloads.azurerm_resource_group.sales \
  /subscriptions/<SALES_SUB_ID>/resourceGroups/rg-a10corp-sales-dev

# Import service resource group (Service subscription)
terraform import \
  module.workloads.azurerm_resource_group.service \
  /subscriptions/<SERVICE_SUB_ID>/resourceGroups/rg-a10corp-service-dev

--- Outputs ---fddf
terraform output
terraform output -json > workloads-outputs.json
terraform output resource_groups

--- Destroy ---
source ../.env && terraform destroy -var-file="environments/dev.tfvars"

###### WORKLOADS ENDS ######

- **Ignore `.gitignore` for Context**: When investigating or searching the codebase, always include files ignored by `.gitignore` or `.geminiignore` (e.g., `.env`, `secure/AZURE_RESOURCES.md`). These contain essential infrastructure context.
- **Helper Script Supremacy**: Always prefer using `./init-plan-apply.sh` for Terraform operations. It handles dynamic backend injection which is critical for this architecture.
- **Explicit Provider Aliasing**: When adding workload resources, always use the aliased providers (`azurerm.hq`, `azurerm.sales`, `azurerm.service`) to ensure resources land in the correct subscription.
- **ACR ID Construction**: Never use `data` sources to fetch the Global ACR ID in the workloads module. Always construct the ID string manually to prevent plan-time deadlocks during environment creation.
- **Documentation Single Source of Truth**: Adhere to the 4-file documentation strategy (`ARCHITECTURE.md`, `DECISIONS.md`, `NEXTSTEPS.md`, `CLAUDE.md`). Do not duplicate facts across these files.
- **Identity Principle**: The `id-a10corp-sales-dev` identity is the AKS Control Plane identity. It must have `AcrPull` on the global ACR and `Network Contributor` on the specific VNet, but **never** on the whole Resource Group (Least Privilege).

---

## END of Dev User Favorites (Do Not Tamper)
**This section contains critical workflow preferences and architectural patterns that must be preserved by all AI assistants and automated tools.**

## 5) How To Run Locally

### Prerequisites
- Azure CLI authenticated: `az login`
- `.env` prepared and sourced: `source .env`

### Using the Helper Script
```bash
# Foundation
./init-plan-apply.sh --foundation plan
./init-plan-apply.sh --foundation apply

# Workloads (Dev)
./init-plan-apply.sh --workloads --env dev plan
./init-plan-apply.sh --workloads --env dev apply
```

---

## 6) Troubleshooting

- **“subscription ID could not be determined”**: Ensure you have run `source .env`.
- **Key Vault access denied**: Verify the `Key Vault Secrets User` role assignment and that your default provider targets the `sub-root` subscription.
- **State locking**: If a state is locked, verify no GitHub Actions are running before manually breaking the lease in the Azure portal.

---

## Appendix: Key File Map

- **Root callers**: `foundation/main.tf`, `workloads/main.tf`
- **Modules**: `modules/common/*`, `modules/foundation/*`, `modules/workloads/*`
- **Pipelines**: `.github/workflows/*`
- **Naming Logic**: `modules/common/naming.tf`