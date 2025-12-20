# Gemini Context: A10 Corp Azure Infrastructure

## Project Overview
This project manages Azure infrastructure for "A10 Corp" using **Terraform**. It follows a **three-module architecture** based on the Azure Cloud Adoption Framework (CAF).

### Core Architecture
1.  **Common** (`modules/common`): Shared library for naming, variables, Key Vault, and Storage integration.
2.  **Foundation** (`foundation/`): Global resources (Management Groups, Subscription associations, Global ACR).
3.  **Workloads** (`workloads/`): Per-environment resources (Resource Groups, VNets, Subnets, Managed Identities).

## Key Technologies
-   **Terraform**: >= 1.0
-   **Azure Provider**: ~> 4.0 (Automatic registration enabled)
-   **Scripting**: Bash (`init-plan-apply.sh`)

## Project Structure
-   `foundation/`: Root module for global infrastructure.
    -   `main.tf`: Calls common + foundation modules.
    -   `registry.tf`: Global ACR definition.
-   `workloads/`: Root module for environment-specific infrastructure.
    -   `main.tf`: Calls common + workloads modules (ACR ID constructed here).
    -   `networking.tf`, `identity.tf`: Workload-specific resources.
-   `modules/`: Reusable Terraform modules.
-   `docs/`: Consolidated documentation.
-   `init-plan-apply.sh`: Helper script with dynamic backend injection.

## Development Workflows

### Prerequisites
-   Azure CLI (`az login`)
-   Terraform installed
-   `.env` file configured (copy from `.env.example`) with:
    -   `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`
    -   `TF_VAR_root_resource_group_name`
    -   `TF_VAR_root_key_vault_name`
    -   `TF_VAR_root_storage_account_name`

### Using the Helper Script (Recommended)
The `init-plan-apply.sh` script handles dynamic backend injection (injecting RG and Storage names during `init`).

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

## CI/CD Pipelines
GitHub Actions with OIDC authentication and dynamic backend injection.

### Workflows
1.  **Foundation Deploy** (`foundation-deploy.yml`):
    *   **Audit**: Full plans stored in `plans/` prefix of root storage account.
2.  **Workloads Deploy** (`workloads-deploy.yml`):
    *   **Safety**: Verifies Foundation health before running.
3.  **Manual Ops** (`terraform-deploy.yml`): Ad-hoc operations.

## Conventions
-   **Naming**: Strict CAF via `naming.tf`. ACRs and Storage use no-hyphen patterns.
-   **Decoupling**: Workloads **construct** the ACR ID string manually to avoid plan-time deadlocks in CI/CD.
-   **Secrets**: Zero secrets in Git. Parameterized root infrastructure.
-   **Tagging**: Centralized automated `Environment` tag (`global` for foundation, `dev|stage|prod` for workloads).

## References
-   See `docs/ARCHITECTURE.md` for deep dive.
-   See `docs/DECISIONS.md` for architectural records.
-   See `docs/USER_MANUAL.md` for operator guides.
