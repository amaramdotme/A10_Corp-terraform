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
   - Open PR → GitHub Actions generates plans (auto) → Approve environment → Apply runs (gated).

---

## 1) Foundations & Workloads Duality

The repo separates “permanent” organizational structure from “replaceable” environment resources.

- **Common library** (`modules/common`)
  - The "brain" of the project.
  - Exposes `naming_patterns`, subscription IDs, and shared variables.
- **Foundation** (one-time, global)
  - Creates management groups, policies, and subscription associations.
  - Deploys Global Artifacts: ACR (`acra10corpsales`) and Central Log Analytics (`log-a10corp-hq`).
  - Never destroy during normal operations.
- **Workloads** (per-environment, safe to destroy/recreate)
  - Creates environment-specific resource groups in the right subscriptions (hq/sales/service).
  - Deploys networking (VNets, Subnets, NSGs, Routes) and identities.
  - Ships all logs to the Foundation's Central Log Analytics Workspace.

---

## 2) Operating Model

### Branching & CI/CD
- **PR to `main`**: Triggers automated plans and Trivy security scans.
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

## 3) Governance & Observability

### Policies (Native Terraform)
- Implemented in `modules/policies/`.
- Assigned to `mg-a10corp-hq`.
- **Key Rules**: Tagging (`Environment`), Locations (`eastus`), SKUs (B/D series), Secure Storage.

### Observability
- **Central Sink**: `log-a10corp-hq` in the Root subscription.
- **Diagnostics**: All Workload VNets/NSGs automatically ship logs here.

### Network Security
- **Perimeter**: All Subnets protected by NSGs.
- **Routing**: Route Tables deployed with default Internet routes (ready for Firewall injection).

---

## 4) Start of Dev User Favorites (Do Not Tamper)
**This section contains critical workflow preferences and architectural patterns that must be preserved by all AI assistants and automated tools.**

================================================================================
TERRAFORM COMMANDS - THREE-MODULE ARCHITECTURE
================================================================================

###### QUICK START HERE ######

###### FOUNDATION STARTS ######
---
Init ---
cd foundation/
source ../.env && terraform init -backend-config="environments/backend.hcl"

#remove backend.tf to store locally
source ../.env && terraform init 

---
Plan & Apply ---
terraform fmt -recursive && terraform validate

terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan

---
State ---
terraform state list
terraform state show module.foundation.azurerm_management_group.hq
terraform state pull > backup-foundation-$(date +%Y%m%d).json

---
Policy Debugging ---
# Check if policy exists in state
terraform state show module.policies.azurerm_management_group_policy_assignment.tagging

---
Import ---
terraform import \
  module.foundation.azurerm_management_group.hq \
  /providers/Microsoft.Management/managementGroups/mg-a10corp-hq

---
Outputs ---
terraform output
terraform output -json > foundation-outputs.json


---
Destroy ---
source ../.env && terraform destroy 

###### FOUNDATION ENDS ######

###### WORKLOADS STARTS ######

---
Init ---
cd workloads
source ../.env && terraform init -backend-config="environments/backend-dev.hcl"

---
Plan & Apply ---
terraform fmt -recursive && terraform validate

terraform plan -var-file="environments/dev.tfvars" -out=workloads.tfplan

terraform apply "workloads.tfplan"

---
State ---
terraform state list
terraform state show module.workloads.azurerm_resource_group.shared_common
terraform state show module.workloads.azurerm_resource_group.sales
terraform state show module.workloads.azurerm_network_security_group.ingress
terraform state pull > backup-workloads-$(date +%Y%m%d).json

---
Import ---
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

---
Outputs ---fddf
terraform output
terraform output -json > workloads-outputs.json
terraform output resource_groups

---
Destroy ---
source ../.env && terraform destroy -var-file="environments/dev.tfvars"

###### WORKLOADS ENDS ######

- **Ignore `.gitignore` for Context**: When investigating or searching the codebase, always include files ignored by `.gitignore` or `.geminiignore` (e.g., `.env`, `secure/AZURE_RESOURCES.md`). These contain essential infrastructure context.
- **Helper Script Supremacy**: Always prefer using `./init-plan-apply.sh` for Terraform operations. It handles dynamic backend injection which is critical for this architecture.
- **Explicit Provider Aliasing**: When adding workload resources, always use the aliased providers (`azurerm.hq`, `azurerm.sales`, `azurerm.service`) to ensure resources land in the correct subscription.
- **ACR ID Construction**: Never use `data` sources to fetch the Global ACR ID in the workloads module. Always construct the ID string manually to prevent plan-time deadlocks during environment creation.
- **Centralized Observability**: All workloads MUST link to the `log_analytics_workspace_id` passed from Foundation. Do not create local workspaces.
- **Documentation Single Source of Truth**: Adhere to the 4-file documentation strategy (`ARCHITECTURE.md`, `DECISIONS.md`, `NEXTSTEPS.md`, `USER_MANUAL.md`). Do not duplicate facts across these files.
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

- **“PolicyDefinitionNotFound”**: Ensure the Policy Definition exists in Azure (or use the generic Display Name lookup).
- **“subscription ID could not be determined”**: Ensure you have run `source .env`.
- **Key Vault access denied**: Verify the `Key Vault Secrets User` role assignment and that your default provider targets the `sub-root` subscription.
- **Trivy Failures**: Check GitHub Actions logs. Use `# trivy:ignore:AVD-AZU-XXXX` for intentional exceptions (like public ingress).
- **State locking**: If a state is locked, verify no GitHub Actions are running before manually breaking the lease in the Azure portal.

---

## Appendix: Key File Map

- **Root callers**: `foundation/main.tf`, `workloads/main.tf`
- **Modules**: `modules/common/*`, `modules/foundation/*`, `modules/workloads/*`, `modules/policies/*`
- **Pipelines**: `.github/workflows/*`
- **Naming Logic**: `modules/common/naming.tf`


## Grok review 
https://grok.com/share/c2hhcmQtNQ_36200033-9e42-45e2-9458-85f9a1648d01
