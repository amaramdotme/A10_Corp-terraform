# Gemini Context: A10 Corp Azure Infrastructure

## Project Overview
This project manages Azure infrastructure for "A10 Corp" using **Terraform**. It follows a **three-module architecture** based on the Azure Cloud Adoption Framework (CAF).

### Core Architecture
1.  **Common** (`modules/common`): Shared library for naming, variables, and Key Vault integration.
2.  **Foundation** (`foundation/`): Global resources (Management Groups, Subscription associations). Deployed once.
3.  **Workloads** (`workloads/`): Per-environment resources (Resource Groups). Deployed per environment (dev, stage, prod).

## Key Technologies
-   **Terraform**: >= 1.0
-   **Azure Provider**: ~> 4.0
-   **Scripting**: Bash (`init-plan-apply.sh`)

## Project Structure
-   `foundation/`: Root module for global infrastructure.
    -   `main.tf`: Defines management groups and subscriptions.
    -   `environments/backend.hcl`: Backend configuration.
-   `workloads/`: Root module for environment-specific infrastructure.
    -   `main.tf`: Defines resource groups.
    -   `environments/`: Contains env-specific backends (`backend-dev.hcl`) and variables (`dev.tfvars`).
-   `modules/`: Reusable Terraform modules.
    -   `common/`: Shared logic (naming, vars).
    -   `foundation/`: Management Group logic.
    -   `workloads/`: Resource Group logic.
-   `init-plan-apply.sh`: Helper script to simplify Terraform workflows.

## Development Workflows

### Prerequisites
-   Azure CLI (`az login`)
-   Terraform installed
-   `.env` file configured (copy from `.env.example`) with `ARM_SUBSCRIPTION_ID` and `ARM_TENANT_ID`.

### Using the Helper Script (Recommended)
The `init-plan-apply.sh` script abstracts the directory switching and argument passing.

**Foundation (Global)**
```bash
./init-plan-apply.sh --foundation init
./init-plan-apply.sh --foundation plan
./init-plan-apply.sh --foundation apply
```

**Workloads (Per Environment)**
Supported environments: `dev`, `stage`, `prod`.
```bash
./init-plan-apply.sh --workloads --env dev init
./init-plan-apply.sh --workloads --env dev plan
./init-plan-apply.sh --workloads --env dev apply
```

### Manual Terraform Commands
**Foundation**
```bash
cd foundation
source ../.env
terraform init -backend-config="environments/backend.hcl"
terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan
```

**Workloads (e.g., Dev)**
```bash
cd workloads
source ../.env
terraform init -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

## CI/CD Pipelines
The project uses GitHub Actions with **OIDC authentication** (no long-lived secrets).

### Workflows
1.  **Foundation Deploy** (`foundation-deploy.yml`):
    *   **Trigger**: Push/PR to `main` affecting `foundation/`.
    *   **Actions**: Plans changes, comments summary on PR, applies on merge.
    *   **Audit**: Uploads full plan to Azure Blob Storage (`storerootblob/foundation`).
2.  **Workloads Deploy** (`workloads-deploy.yml`):
    *   **Trigger**: Push/PR to `main` or manual dispatch.
    *   **Actions**: Targets specific env (`dev`/`stage`/`prod`).
    *   **Safety**: Checks if Foundation is healthy before running.
3.  **Manual Ops** (`terraform-deploy.yml`):
    *   **Trigger**: Manual dispatch only.
    *   **Actions**: Ad-hoc Plan/Apply/Destroy for any environment.
4.  **OIDC Test** (`test-oidc.yml`):
    *   **Trigger**: Manual.
    *   **Actions**: Verifies Azure connectivity and RBAC permissions.

## Conventions
-   **Naming**: Follows strict CAF standards via `modules/common/naming.tf` (e.g., `rg-a10corp-sales-dev`).
-   **State**: Stored in Azure Blob Storage (`storerootblob`).
-   **Secrets**: **NO secrets in Git**. Uses Azure Key Vault (`kv-root-terraform`) to fetch sensitive IDs at runtime.
-   **CI/CD**: GitHub Actions using OIDC (Workload Identity Federation).

## References
-   See `ARCHITECTURE.md` for deep dive.
-   See `DECISIONS.md` for architectural records.
