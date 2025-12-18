# Architecture and Implementation Decisions

This document captures key decisions made during the implementation of the A10 Corp Azure infrastructure with Terraform.

---

## Decision 1: Terraform Installation Location

**Context**: Installing Terraform binary in WSL environment

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Windows binary via WSL (option 2)** | Use Windows Terraform.exe from WSL by calling it with `.exe` extension | ❌ Path translation issues between Windows/Linux<br>❌ Performance overhead<br>❌ File permission complications<br>✅ No installation needed |
| **Linux binary in ~/bin (chosen)** | Download Linux version and install to user's home bin directory | ✅ Native Linux execution<br>✅ No path translation issues<br>✅ Better performance<br>❌ Required manual installation |
| **System-wide installation (/usr/local/bin)** | Install with sudo to system directory | ✅ Available to all users<br>✅ Standard location<br>❌ Requires sudo password |

**Decision**: Install Linux binary to `~/bin` directory

**Summary**: Chose Linux binary in user directory to avoid path translation issues and sudo requirements while maintaining native performance.

---

## Decision 2: Azure Resource Provider Registration

**Context**: Terraform attempting to auto-register Azure Resource Providers causing timeouts

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Automatic registration (default)** | Let Terraform register all Resource Providers automatically | ❌ Requires elevated permissions<br>❌ Slow/timeout on network issues<br>✅ Ensures all providers available |
| **Disable registration (chosen)** | Set `resource_provider_registrations = "none"` in provider config | ✅ Faster execution<br>✅ Works with limited permissions<br>❌ Manual registration needed if provider missing |

**Decision**: Disable automatic registration with `resource_provider_registrations = "none"`

**Summary**: Disabled auto-registration to avoid timeout issues and permission requirements, as the needed providers (Management Groups, Resource Groups) were already registered.

---

## Decision 3: Management Group Hierarchy Root Reference

**Context**: How to reference the Tenant Root Management Group in Terraform

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Data source lookup** | Use `data "azurerm_management_group"` to query tenant root | ❌ Requires read permissions<br>❌ Extra API call<br>✅ Dynamic discovery |
| **Direct ID reference (chosen)** | Hard-code tenant root path: `/providers/Microsoft.Management/managementGroups/${var.tenant_id}` | ✅ No extra permissions needed<br>✅ Faster execution<br>❌ Less dynamic |

**Decision**: Use direct ID reference to tenant root

**Summary**: Direct reference avoided permission issues and was more reliable since tenant ID is already known.

---

## Decision 4: Subscription Creation Approach

**Context**: Need multiple subscriptions (shared, sales, service) for the architecture

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Terraform-managed creation** | Create subscriptions programmatically via Terraform | ❌ Requires billing account access<br>❌ Individual account type doesn't support it<br>✅ Fully automated |
| **Manual creation in Portal (chosen)** | Create subscriptions through Azure Portal UI | ✅ Works with any account type<br>✅ Simple for small numbers<br>❌ Manual process<br>❌ Not automated |

**Decision**: Create subscriptions manually through Azure Portal

**Summary**: Manual creation was necessary due to Individual billing account type limitations. Sales subscription was created; Service subscription hit quota limits and used shared subscription instead.

---

## Decision 5: Subscription Association for Sales

**Context**: Sales subscription was manually created under the management group

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Skip Terraform association** | Don't manage the association in Terraform since it exists | ❌ Not tracked in state<br>❌ Drift if manual changes occur<br>✅ Avoids conflicts |
| **Import and manage (chosen)** | Add association resource to Terraform configuration | ✅ Full state tracking<br>✅ Infrastructure as code<br>✅ Detects drift<br>❌ Potential for conflicts on first apply |

**Decision**: Manage subscription association in Terraform

**Summary**: Added the association resource to ensure complete infrastructure tracking and prevent configuration drift.

---

## Decision 6: Naming Convention Enforcement

**Context**: Need standardized, Azure CAF-compliant resource naming

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Manual string concatenation (chosen)** | Use `locals` with string interpolation | ✅ Simple, no external dependencies<br>✅ Full control over naming<br>✅ Easy to understand and maintain<br>❌ Manual CAF compliance verification |
| **Azure CAF Naming Module** | Use `aztfmod/azurecaf` Terraform provider | ✅ Automated CAF compliance<br>✅ Built-in validation<br>✅ Character limit handling<br>❌ External dependency<br>❌ Additional provider overhead |
| **Custom naming module** | Build own module with naming logic | ✅ Full control<br>✅ Custom rules<br>❌ Maintenance overhead<br>❌ Reinventing the wheel |

**Decision**: Use pure Terraform locals with string concatenation

**Summary**: After initially evaluating the azurecaf provider, decided to use pure Terraform locals for simplicity and to eliminate external dependencies. The naming pattern is straightforward enough that manual implementation provides better transparency and control.

**Implementation**: Centralized all naming logic in naming.tf with a reusable pattern:
- Created `local.resource_type_map` for CAF type codes (rg, mg, vm, pg, etc.)
- Created `local.workloads` global list for all workloads (hq, shared, sales, service)
- Split resources into two categories:
  - `local.resources_with_env` - Resources that include environment suffix (e.g., rg, vm)
  - `local.resources_without_env` - Resources without environment suffix (e.g., mg)
- Generated `local.naming_patterns` using nested `for` loops with `merge()`
- Exposed final names via `local.naming_patterns["resource_type"]["workload"]` pattern
- Resource files simply reference: `local.naming_patterns["azurerm_resource_group"]["sales"]`

**Example output:**
- `local.naming_patterns["azurerm_resource_group"]["sales"]` → `"rg-a10corp-sales-dev"`
- `local.naming_patterns["azurerm_management_group"]["sales"]` → `"mg-a10corp-sales"`

This approach provides:
- Single source of truth for naming in naming.tf
- No external provider dependencies
- No duplication of naming logic across files
- Easy to add new workloads (just update `local.workloads` list)
- Easy to add new resource types (just update `local.resource_type_map`)
- Clean, readable resource definitions without naming boilerplate
- Full CAF compliance through manual pattern adherence

---

## Decision 7: Multi-Environment Management Strategy

**Context**: Need to support dev, stage, and prod environments with same code

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Terraform Workspaces (option 1)** | Use `terraform workspace` to switch environments | ✅ Cleanest CLI experience<br>❌ Shared state backend<br>❌ Easy to make mistakes (wrong workspace)<br>❌ No environment isolation<br>✅ Good for learning |
| **Environment-specific .tfvars files (chosen)** | Separate variable files per environment | ✅ Clear separation<br>✅ Explicit `-var-file` requirement<br>✅ Different backends possible<br>✅ Better for CI/CD<br>❌ Slightly more verbose commands |
| **Separate directories** | Completely separate directories per environment | ✅ Maximum isolation<br>✅ Different state backends<br>❌ Code duplication<br>❌ Harder to maintain consistency |

**Decision**: Use environment-specific `.tfvars` files

**Summary**: Chose `.tfvars` approach for production-readiness, explicit environment selection, and ability to use different backends per environment while maintaining single codebase.

---

## Decision 8: Azure CAF Naming - Environment Suffix

**Context**: Resource groups and resources should include environment designation per CAF

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Environment in resource name only** | Include env only in `name` parameter | ❌ Not CAF compliant<br>❌ Inconsistent format |
| **Environment as suffix (chosen)** | Append environment to naming pattern in locals | ✅ CAF compliant format<br>✅ Consistent naming<br>✅ Clear environment identification |
| **No environment designation** | Same names across all environments | ❌ Name conflicts<br>❌ Confusion between environments<br>❌ Not CAF compliant |

**Decision**: Use environment as suffix in naming patterns

**Summary**: Implemented proper CAF naming with environment suffix to ensure resources are clearly identified by environment (dev/stage/prod) and prevent naming conflicts. Resources are categorized into `resources_with_env` (includes environment) and `resources_without_env` (no environment suffix, like management groups).

---

## Decision 9: CI/CD Authentication Method

**Context**: Need secure authentication for GitHub Actions to deploy Azure infrastructure without storing long-lived secrets

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Service Principal with Client Secret** | Store service principal credentials in GitHub Secrets | ⚠️ Long-lived secrets (years)<br>⚠️ Secret rotation required<br>⚠️ Risk of secret leakage<br>✅ Simple to set up<br>✅ Well-documented |
| **OIDC Workload Identity Federation (chosen)** | Use OpenID Connect with federated credentials - no secrets stored | ✅ No long-lived secrets stored<br>✅ Temporary tokens only (hours)<br>✅ Microsoft best practice<br>✅ Automatic token rotation<br>❌ Slightly more complex setup<br>❌ Requires federated credential configuration |
| **Self-Hosted Runners with Managed Identity** | Run GitHub runners on Azure VMs with managed identity | ✅ No secrets at all<br>✅ Very secure<br>❌ Infrastructure overhead<br>❌ Runner maintenance required<br>❌ Most complex |

**Decision**: Use OIDC Workload Identity Federation

**Summary**: Chosen for production-grade security without storing any long-lived secrets in GitHub. Uses OpenID Connect trust relationship between GitHub and Azure AD, where GitHub Actions receives temporary tokens that Azure validates. This eliminates the risk of secret leakage and follows Microsoft's recommended approach for CI/CD authentication.

**Implementation Plan**:
1. Create App Registration in Azure AD (Entra ID)
2. Add federated credentials for each GitHub environment (dev, stage, prod)
3. Assign appropriate Azure RBAC permissions (Contributor on subscriptions, Management Group Contributor)
4. Store non-sensitive IDs in GitHub environment variables (client ID, tenant ID)
5. GitHub Actions workflow uses `azure/login@v1` with OIDC parameters

**Security Benefits**:
- Zero secrets stored in GitHub
- Tokens expire automatically (hours vs years)
- Azure validates GitHub's identity via OIDC
- Audit trail of which GitHub workflow/branch requested access
- No secret rotation burden

---

## Decision 10: Sensitive Data Management in Git

**Context**: How to handle subscription IDs, tenant IDs, and other infrastructure identifiers in version control

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Ignore all .tfvars files** | Keep `.tfvars` in `.gitignore`, never commit | ✅ Maximum safety<br>❌ Environment configs not versioned<br>❌ Team members recreate configs<br>❌ CI/CD needs to generate files |
| **Commit all .tfvars files** | Version control everything for reproducibility | ❌ Risk of committing secrets<br>❌ Public repo exposes all IDs<br>✅ Easy team collaboration<br>✅ CI/CD ready |
| **Selective commit with GitHub Secrets (chosen)** | Commit non-sensitive config, inject sensitive values via environment variables | ✅ Environment configs versioned<br>✅ Sensitive IDs in GitHub Secrets only<br>✅ Clear separation of concerns<br>✅ CI/CD friendly<br>❌ Two sources of truth |

**Decision**: Commit environment `.tfvars` with non-sensitive values, inject sensitive IDs via `TF_VAR_*` environment variables in CI/CD

**Summary**: Modified `.gitignore` to allow `environments/*.tfvars` while excluding sensitive values from those files. Subscription IDs, tenant IDs, and other sensitive identifiers are passed as environment variables in GitHub Actions using `TF_VAR_subscription_id` pattern. This provides version control for infrastructure configuration while keeping sensitive data secure in GitHub Secrets.

**Implementation**:
- `.gitignore`: `*.tfvars` but `!environments/*.tfvars`
- Committed in `.tfvars`: `org_name`, `environment`, `location`, `common_tags`
- GitHub Secrets: `AZURE_SUBSCRIPTION_ID`, `AZURE_SALES_SUBSCRIPTION_ID`, `AZURE_SERVICE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`
- Workflow injects via: `TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}`

**Rationale**: Public repository requires careful handling of Azure resource IDs. While subscription/tenant IDs aren't authentication secrets, exposing them publicly provides reconnaissance information for attackers. Storing in GitHub Secrets adds defense-in-depth.

---

## Decision 11: Module Separation Strategy

**Context**: Need to separate stable organizational structure from dynamic environment-specific resources

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Monolithic structure (initial)** | All resources in single Terraform root | ❌ Can't destroy RGs without affecting MGs<br>❌ Single state file for everything<br>❌ Risky operations<br>✅ Simple to understand |
| **Two-module architecture (chosen)** | Separate foundation (MGs) from workloads (RGs) | ✅ Safe destroy/recreate of RGs<br>✅ Independent state files<br>✅ Clear lifecycle separation<br>✅ Scalable design<br>❌ More complex initial setup |
| **Three-module architecture** | Foundation + Workloads + Networking layers | ✅ Maximum separation<br>❌ Over-engineered for current needs<br>❌ More complexity |

**Decision**: Implement two-module architecture (Foundation + Workloads)

**Summary**: Refactored monolithic Terraform code into two distinct modules with separate lifecycles and state management. This enables safe destruction/recreation of environment-specific resource groups without risking the organizational management group structure.

**Implementation**:

### Pre-Terraform Manual Setup (Never Destroyed)
**Purpose**: Infrastructure to support Terraform itself

**Location**: Azure Portal (manual creation)

**Resources**:
- Resource Group: `rg-root-iac` (in sub-root subscription)
- Key Vault: `kv-a10corp-terraform` (stores sensitive .tfvars)
- Storage Account: `sta10corptfstate` (stores Terraform state files)
  - Containers: `foundation-dev`, `foundation-stage`, `foundation-prod`, `workloads-dev`, `workloads-stage`, `workloads-prod`

**Azure Hierarchy Pre-Terraform**:
```
Tenant Root MG (Azure default)
├── sub-root (fdb297a9-2ece-469c-808d-a8227259f6e8)
├── sub-hq (da1ba383-2bf5-4ee9-8b5f-fc6effb0a100)
├── sub-sales (385c6fcb-c70b-4aed-b745-76bd608303d7)
└── sub-service (aef7255d-42b5-4f84-81f2-202191e8c7d1)
```

### Module 1: Foundation
**Purpose**: One-time organizational setup (rarely changed, never destroyed)

**Location**: `modules/foundation/` and `foundation/` (root)

**Resources**:
- Management Group: `mg-a10corp-hq` (parent MG)
- Management Groups: `mg-a10corp-sales`, `mg-a10corp-service` (child MGs)
- Subscription associations:
  - `sub-hq` → `mg-a10corp-hq`
  - `sub-sales` → `mg-a10corp-sales`
  - `sub-service` → `mg-a10corp-service`

**State**: `foundation-<env>.tfstate` in Azure Storage

**Target Hierarchy After Foundation Module**:
```
Tenant Root MG
├── sub-root (stays here, never moved)
└── mg-a10corp-hq (created by Terraform)
    ├── sub-hq (moved here by Terraform)
    ├── mg-a10corp-sales (created by Terraform)
    │   └── sub-sales (moved here by Terraform)
    └── mg-a10corp-service (created by Terraform)
        └── sub-service (moved here by Terraform)
```

### Module 2: Workloads
**Purpose**: Environment-specific resource groups (can be destroyed/recreated)

**Location**: `modules/workloads/` and `workloads/` (root)

**Resources**:
- Resource Groups per environment:
  - `rg-a10corp-hq-{env}` in sub-hq
  - `rg-a10corp-sales-{env}` in sub-sales
  - `rg-a10corp-service-{env}` in sub-service

**State**: `workloads-<env>.tfstate` in Azure Storage

### Shared Variables (Combined Approach)
**Non-sensitive (in repo)**: `environments/{env}.tfvars`
- `org_name`, `environment`, `location`, `common_tags`

**Sensitive (Key Vault)**: `terraform-{env}-sensitive`
- `tenant_id`, `hq_subscription_id`, `sales_subscription_id`, `service_subscription_id`

*Note: sub-root is NOT included as it remains in Tenant Root MG and is managed manually*

### Directory Structure
```
terraform/
├── foundation/              # Module 1 root
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   └── environments/
│       ├── dev.tfvars       # Non-sensitive (in repo)
│       ├── stage.tfvars
│       └── prod.tfvars
├── workloads/               # Module 2 root
│   ├── backend.tf
│   ├── providers.tf
│   ├── main.tf
│   └── environments/
│       ├── dev.tfvars       # Non-sensitive (in repo)
│       ├── stage.tfvars
│       └── prod.tfvars
├── modules/
│   ├── foundation/          # Foundation module code
│   └── workloads/           # Workloads module code
├── scripts/
│   ├── fetch-sensitive-tfvars.sh
│   ├── upload-sensitive-tfvars.sh
│   ├── init-foundation.sh
│   └── init-workloads.sh
└── secure/                  # Gitignored
    ├── foundation/
    │   └── <env>-sensitive.tfvars
    └── workloads/
        └── <env>-sensitive.tfvars
```

**Benefits**:
1. **Separation of Concerns**: Stable foundation vs dynamic workloads
2. **Safe Operations**: Destroy/recreate RGs without risk to MGs
3. **Independent State**: Each module has isolated state files
4. **Scalability**: Easy to add new workloads or environments
5. **Clear Lifecycle Management**: Different update cadences for different layers

**Workflows**:
- **Foundation**: Deployed once per environment, rarely updated
- **Workloads**: Can be destroyed/recreated frequently for testing

**CI/CD**: Separate GitHub Actions workflows:
- `foundation-deploy.yml` - Deploys/updates management groups
- `workloads-deploy.yml` - Deploys/destroys resource groups

---

## Decision 12: Sensitive Data Storage Strategy

**Context**: Need enterprise-grade solution for sharing sensitive .tfvars across team while maintaining security

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **GitHub Secrets only** | Store all sensitive values as GitHub Secrets, use TF_VAR_* injection | ✅ Works for CI/CD<br>❌ No solution for local development<br>❌ Team members can't share configs |
| **Azure Key Vault for .tfvars (chosen)** | Store sensitive .tfvars in Key Vault, fetch on-demand | ✅ Centralized management<br>✅ Works for local + CI/CD<br>✅ Audit logs<br>✅ RBAC access control<br>❌ Requires Key Vault setup |
| **Encrypted Git (git-crypt)** | Encrypt .tfvars in repo with git-crypt | ✅ Files in repo<br>❌ Complex key management<br>❌ GPG key distribution |
| **Terraform Cloud** | Use Terraform Cloud variable sets | ✅ Enterprise solution<br>❌ Requires license<br>❌ All runs through cloud |

**Decision**: Hybrid approach - Azure Key Vault for sensitive .tfvars + GitHub Secrets

**Summary**: Implemented hybrid strategy where non-sensitive configuration is committed to the repository and sensitive values are stored in Azure Key Vault. Both local developers and GitHub Actions fetch sensitive .tfvars from Key Vault as needed.

**Implementation**:

### Non-Sensitive (Committed to Repo)
**Files**: `environments/*.tfvars` (shared by both modules)

**Content**:
```hcl
org_name    = "a10corp"
environment = "dev"
location    = "eastus"
common_tags = { ... }
```

### Sensitive (Azure Key Vault)
**Secrets** (combined approach - one secret per environment, shared by both modules):
- `terraform-dev-sensitive`
- `terraform-stage-sensitive`
- `terraform-prod-sensitive`

**Content**:
```hcl
tenant_id               = "..."
hq_subscription_id      = "..."
sales_subscription_id   = "..."
service_subscription_id = "..."
```

### Local Development Workflow
```bash
# Fetch sensitive .tfvars from Key Vault (once per environment)
./scripts/fetch-sensitive-tfvars.sh dev

# Run Terraform with both files
cd foundation/
terraform plan \
  -var-file="../environments/dev.tfvars" \
  -var-file="../secure/dev-sensitive.tfvars"

cd ../workloads/
terraform plan \
  -var-file="../environments/dev.tfvars" \
  -var-file="../secure/dev-sensitive.tfvars"
```

### GitHub Actions Workflow
```yaml
- name: Fetch sensitive tfvars from Key Vault
  run: |
    az keyvault secret show \
      --vault-name "kv-a10corp-terraform" \
      --name "terraform-${{ inputs.environment }}-sensitive" \
      --query "value" -o tsv > sensitive.tfvars

- name: Terraform Plan (Foundation or Workloads)
  run: |
    terraform plan \
      -var-file="environments/${{ inputs.environment }}.tfvars" \
      -var-file="sensitive.tfvars"
```

**Security Benefits**:
- Sensitive IDs never committed to Git
- Centralized management (single source of truth)
- Audit logs (who accessed when)
- RBAC (role-based access control)
- Works for both local development and CI/CD
- Ephemeral files (deleted after GitHub Actions run)

**Team Collaboration**:
- New developers: `./scripts/fetch-sensitive-tfvars.sh <module> <env>`
- Updates: `./scripts/upload-sensitive-tfvars.sh <module> <env>`
- Access controlled via Azure AD + Key Vault policies

---

## Decision 13: Combined vs Separate Sensitive .tfvars Files

**Context**: Should foundation and workloads modules have separate sensitive .tfvars in Key Vault, or share a single file?

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Separate sensitive .tfvars per module** | Store `terraform-foundation-<env>-sensitive` and `terraform-workloads-<env>-sensitive` separately | ✅ Isolated secrets per module<br>✅ Granular access control<br>❌ Duplication of subscription IDs<br>❌ 6 total secrets to manage<br>❌ Risk of inconsistency |
| **Combined sensitive .tfvars (chosen)** | Single `terraform-<env>-sensitive` file shared by both modules | ✅ DRY (no duplication)<br>✅ Single source of truth<br>✅ Only 3 secrets to manage<br>✅ Simpler workflow<br>❌ Less granular access control |
| **Individual secrets (most granular)** | Each value as separate secret (terraform-dev-tenant-id, terraform-dev-sub-hq-id, etc.) | ✅ Maximum granularity<br>❌ 12+ secrets to manage<br>❌ Complex fetch logic<br>❌ Over-engineered |

**Decision**: Use combined sensitive .tfvars file shared by both modules

**Summary**: Both foundation and workloads modules need the same subscription IDs, and tenant_id is global. Storing these in separate files creates unnecessary duplication and risk of divergence. A single shared sensitive .tfvars file per environment is simpler, more maintainable, and follows DRY principles.

**Implementation**:

### Key Vault Structure (Simplified)
```
kv-a10corp-terraform/
├── terraform-dev-sensitive      # Shared by foundation + workloads
├── terraform-stage-sensitive    # Shared by foundation + workloads
└── terraform-prod-sensitive     # Shared by foundation + workloads
```

### Content of Each Secret
```hcl
# terraform-dev-sensitive (used by BOTH modules)
tenant_id               = "8116fad0-5032-463e-b911-cc6d1d75001d"
hq_subscription_id      = "da1ba383-2bf5-4ee9-8b5f-fc6effb0a100"
sales_subscription_id   = "385c6fcb-c70b-4aed-b745-76bd608303d7"
service_subscription_id = "aef7255d-42b5-4f84-81f2-202191e8c7d1"
```

### Fetch Script (Simplified)
```bash
# Single command fetches for ALL modules
./scripts/fetch-sensitive-tfvars.sh dev

# Creates: secure/dev-sensitive.tfvars
# Used by: foundation/ and workloads/
```

**Benefits**:
- **Reduced Complexity**: 3 secrets instead of 6 (50% reduction)
- **Consistency Guaranteed**: Impossible for foundation and workloads to have mismatched subscription IDs
- **Simpler Scripts**: One fetch operation instead of two
- **Single Source of Truth**: No risk of updating one module's secrets but forgetting the other
- **Easier Management**: Fewer secrets to rotate, update, and audit

**Rationale**: The separate module architecture is for *Terraform state and lifecycle management*, not for secret isolation. Both modules operate on the same Azure tenant and subscriptions, so sharing sensitive configuration makes sense.

---

## Decision 14: Secret Injection Method - Native Terraform vs External Scripts

**Context**: How should Terraform retrieve sensitive values from Azure Key Vault during execution?

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **External script + .tfvars files** | Use bash scripts to fetch secrets from Key Vault, write to local .tfvars files, pass via `-var-file` | ✅ Secrets not in Terraform state<br>✅ Works offline after fetch<br>✅ Easy to debug (inspect files)<br>❌ Extra step before terraform commands<br>❌ Script maintenance overhead<br>❌ Local file management |
| **Native Terraform data sources (chosen)** | Use `data "azurerm_key_vault_secret"` to fetch secrets directly during plan/apply | ✅ No external scripts needed<br>✅ Works seamlessly in CI/CD<br>✅ Audit trail via Key Vault logs<br>✅ RBAC enforced automatically<br>✅ Simpler workflow (just `terraform plan`)<br>⚠️ Secrets in state file (acceptable trade-off) |
| **Terraform Cloud variable sets** | Use Terraform Cloud to manage sensitive variables | ✅ Enterprise solution<br>✅ UI for secret management<br>❌ Requires Terraform Cloud license<br>❌ All runs through cloud<br>❌ Additional dependency |

**Decision**: Use native Terraform `azurerm_key_vault_secret` data sources with individual secrets per value

**Summary**: Native Terraform Key Vault integration provides the cleanest developer experience and best CI/CD integration. While secrets are stored in the Terraform state file, this is an acceptable trade-off since state files should already be secured (encrypted at rest, access-controlled). The benefits of eliminating external scripts and simplifying the workflow outweigh the theoretical security concern of secrets in state.

**Implementation**:

### Key Vault Structure (Optimized - Only Subscription IDs)

**Optimization**: After initial implementation, we optimized to use `azurerm_client_config` for tenant_id instead of storing it in Key Vault. Tenant ID is derived from the authenticated Azure context (ARM_TENANT_ID environment variable), eliminating redundancy.

```
kv-root-terraform/
# Per-environment secrets (3 secrets × 3 environments = 9 total)
# Only subscription IDs that are actually used in Terraform resources
├── terraform-dev-hq-sub-id       # da1ba383-2bf5-4ee9-8b5f-fc6effb0a100
├── terraform-dev-sales-sub-id    # 385c6fcb-c70b-4aed-b745-76bd608303d7
├── terraform-dev-service-sub-id  # aef7255d-42b5-4f84-81f2-202191e8c7d1
├── terraform-stage-hq-sub-id
├── terraform-stage-sales-sub-id
├── terraform-stage-service-sub-id
├── terraform-prod-hq-sub-id
├── terraform-prod-sales-sub-id
└── terraform-prod-service-sub-id

# NOT in Key Vault (derived from authenticated context):
# - tenant_id → from data.azurerm_client_config.current.tenant_id
# - root_subscription_id → from data.azurerm_client_config.current.subscription_id
```

### Terraform Code Pattern

```hcl
# data-sources.tf
# Get current Azure client configuration (authenticated context)
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "terraform" {
  name                = "kv-root-terraform"
  resource_group_name = "rg-root-iac"
}

data "azurerm_key_vault_secret" "hq_subscription_id" {
  name         = "terraform-${var.environment}-hq-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

data "azurerm_key_vault_secret" "sales_subscription_id" {
  name         = "terraform-${var.environment}-sales-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

data "azurerm_key_vault_secret" "service_subscription_id" {
  name         = "terraform-${var.environment}-service-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}

# Locals for convenient access
locals {
  # From authenticated context (no Key Vault needed)
  tenant_id            = data.azurerm_client_config.current.tenant_id
  root_subscription_id = data.azurerm_client_config.current.subscription_id  # sub-root

  # From Key Vault (only subscriptions used in resources)
  hq_subscription_id      = data.azurerm_key_vault_secret.hq_subscription_id.value
  sales_subscription_id   = data.azurerm_key_vault_secret.sales_subscription_id.value
  service_subscription_id = data.azurerm_key_vault_secret.service_subscription_id.value
}
```

### Updated providers.tf (Circular Dependency Resolution)

**Critical**: The default provider CANNOT use Key Vault secrets for subscription_id/tenant_id because that creates a circular dependency (provider needs Key Vault, Key Vault data sources need provider). Solution: Use environment variables for default provider, Key Vault secrets for aliased providers.

```hcl
# Default provider - uses Azure CLI authentication (az login) or GitHub Actions OIDC
# Authenticates to sub-root subscription by default (where Key Vault lives)
# subscription_id/tenant_id NOT set here to avoid circular dependency with Key Vault data sources
# Instead, use environment variables: ARM_SUBSCRIPTION_ID and ARM_TENANT_ID
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  # NO subscription_id or tenant_id here - uses ARM_SUBSCRIPTION_ID and ARM_TENANT_ID env vars
}

# Provider for HQ subscription - uses Key Vault secret
provider "azurerm" {
  alias                           = "hq"
  features {}
  subscription_id                 = local.hq_subscription_id  # Fetched from Key Vault
  resource_provider_registrations = "none"
}

# Provider for Sales subscription - uses Key Vault secret
provider "azurerm" {
  alias                           = "sales"
  features {}
  subscription_id                 = local.sales_subscription_id  # Fetched from Key Vault
  resource_provider_registrations = "none"
}

# Provider for Service subscription - uses Key Vault secret
provider "azurerm" {
  alias                           = "service"
  features {}
  subscription_id                 = local.service_subscription_id  # Fetched from Key Vault
  resource_provider_registrations = "none"
}
```

### Environment Variables for Local Development (.env file)

To avoid the circular dependency, the default azurerm provider uses environment variables instead of Key Vault secrets. This is configured via a `.env` file that mirrors the GitHub Actions environment variables.

**File: `.env` (gitignored)**
```bash
# Azure Environment Variables for Local Terraform Development
# These mirror the GitHub Actions environment variables
# Usage: source .env

# Azure Subscription ID (sub-root where Key Vault lives)
export ARM_SUBSCRIPTION_ID="fdb297a9-2ece-469c-808d-a8227259f6e8"

# Azure Tenant ID
export ARM_TENANT_ID="8116fad0-5032-463e-b911-cc6d1d75001d"
```

**File: `.env.example` (committed to repo)**
```bash
# Azure Environment Variables for Local Terraform Development
# Copy this file to .env and fill in your values
# Usage: source .env (or use direnv)

# Azure Subscription ID (sub-root where Key Vault lives)
export ARM_SUBSCRIPTION_ID="your-subscription-id-here"

# Azure Tenant ID
export ARM_TENANT_ID="your-tenant-id-here"

# To get these values, run: az account show
```

**Updated .gitignore**
```gitignore
# Environment variables (contains subscription/tenant IDs)
.env
.env.*
!.env.example
```

### Updated variables.tf

```hcl
# Remove subscription/tenant variables - they're now read from Key Vault
# variable "subscription_id" { ... }        # REMOVED
# variable "tenant_id" { ... }              # REMOVED
# variable "sales_subscription_id" { ... }  # REMOVED
# variable "service_subscription_id" { ... } # REMOVED

# Keep only non-sensitive variables
variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "org_name" {
  description = "Organization name for naming convention"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
```

### Updated environments/*.tfvars

```hcl
# environments/dev.tfvars (no sensitive data)
environment = "dev"
org_name    = "a10corp"
location    = "eastus"

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "A10Corp"
  CostCenter  = "Engineering"
}

# Subscription/tenant IDs removed - now fetched from Key Vault
```

### Workflow Changes

**Before (with external scripts):**
```bash
./scripts/fetch-sensitive-tfvars.sh dev
terraform plan -var-file="environments/dev.tfvars" -var-file="secure/dev-sensitive.tfvars"
```

**After (native Terraform with .env file):**
```bash
# One-time setup: Create .env file from template
cp .env.example .env
# Edit .env with your subscription/tenant IDs (from: az account show)

# Daily workflow: Source .env and run terraform
source .env
terraform plan -var-file="environments/dev.tfvars"
# Terraform fetches subscription IDs from Key Vault automatically!
```

**Local Development vs CI/CD Comparison:**

| Environment | Default Provider Auth | Subscription IDs Source |
|-------------|----------------------|-------------------------|
| **Local Development** | Azure CLI (`az login`) + `.env` file (ARM_SUBSCRIPTION_ID, ARM_TENANT_ID) | Key Vault data sources |
| **GitHub Actions** | OIDC (`azure/login@v1`) - auto-sets ARM_SUBSCRIPTION_ID, ARM_TENANT_ID | Key Vault data sources |

Both environments use the same Terraform code - the only difference is how ARM environment variables are set.

### GitHub Actions Integration

```yaml
- name: Azure Login via OIDC
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  # This action automatically sets ARM_SUBSCRIPTION_ID and ARM_TENANT_ID environment variables

- name: Terraform Plan
  run: |
    terraform plan -var-file="environments/${{ inputs.environment }}.tfvars"
  # No .env file or Key Vault fetch script needed!
  # - Default provider uses ARM_* env vars (set by azure/login)
  # - Aliased providers use Key Vault data sources (authenticated via azure/login)
```

**Benefits**:
1. **Simplified Workflow**: One command instead of two (no fetch script)
2. **Better CI/CD**: GitHub Actions just needs OIDC authentication
3. **Audit Trail**: Key Vault logs every Terraform access
4. **RBAC Enforcement**: Uses same credentials as other Terraform operations
5. **Team Onboarding**: New developers just run `az login` and `terraform plan`
6. **No Script Maintenance**: Eliminates fetch/upload script complexity

**Trade-offs Accepted**:
1. **Secrets in State**: State file contains subscription IDs (but state should be secured anyway)
2. **Network Dependency**: Terraform must reach Key Vault during execution (acceptable for cloud infrastructure)

**Optimization Applied**:
- Originally stored 12 secrets (4 per environment including tenant_id)
- Optimized to 9 secrets (3 per environment, tenant_id from azurerm_client_config)
- Tenant ID and root subscription ID derived from authenticated context (standard Terraform pattern)

**Security Considerations**:
- Terraform state files already require encryption at rest (Azure Storage with encryption)
- State file access already requires authentication (Azure Storage RBAC)
- Key Vault access logs provide audit trail of when secrets were accessed
- Marking data sources as `sensitive = true` prevents exposure in plan output

**Migration Path**:
1. Split existing combined secrets into individual secrets in Key Vault
2. Remove variable declarations from `variables.tf`
3. Create `data-sources.tf` with Key Vault data sources
4. Update `providers.tf` to use locals instead of variables
5. Clean up `environments/*.tfvars` to remove sensitive values
6. Test with `terraform plan` to verify Key Vault access
7. Delete `secure/` directory and fetch scripts (no longer needed)

---

## Overall Summary

The implementation prioritized:

1. **Reliability over convenience** - Chose stable, proven approaches even if slightly more manual
2. **Azure CAF compliance** - Followed Microsoft Cloud Adoption Framework standards throughout
3. **Production readiness** - Selected patterns suitable for enterprise use (environment separation, naming standards)
4. **Permission awareness** - Worked within permission constraints of Individual Azure account
5. **Infrastructure as Code principles** - Ensured all infrastructure is tracked in Terraform state
6. **Modularity** - Separated stable foundation from dynamic workloads
7. **Security** - Sensitive data in Key Vault, non-sensitive in Git

**Key Architectural Outcomes**:
- **Three-module architecture**: Common (shared logic) + Foundation (MGs) + Workloads (RGs)
- **Centralized configuration**: Common module contains all variables, naming, and Key Vault data sources
- **Management Group hierarchy**: Tenant Root → mg-a10corp-hq → (mg-a10corp-sales, mg-a10corp-service)
- **Environment-based naming**: `rg-{org}-{workload}-{environment}` format for workloads, no environment for foundation
- **Multi-environment support**: Workloads have dev/stage/prod variants, foundation is global
- **CAF-compliant naming**: Pure Terraform locals (no external providers)
- **No sensitive values in Git**: All subscription IDs fetched from Key Vault by common module
- **OIDC authentication**: Zero long-lived secrets in GitHub
- **Separate state files**: `foundation.tfstate` (single) and `workloads-<env>.tfstate` (per environment)

---

## Decision 15: Three-Module Architecture with Centralized Common Module

**Date**: 2025-12-17

**Context**: After implementing the initial two-module architecture (foundation + workloads), we identified significant duplication in variable definitions, naming logic, and Key Vault data sources between modules.

| Option | Description | Trade-offs |
|--------|-------------|------------|
| **Two-module architecture (initial)** | Foundation and workloads modules, each with own variables and data sources | ❌ Duplicated variable definitions<br>❌ Duplicated Key Vault data sources<br>❌ Duplicated naming logic<br>❌ Risk of configuration drift<br>✅ Simple to understand |
| **Three-module architecture (chosen)** | Common module centralizes all shared logic, foundation and workloads are thin wrappers | ✅ Single source of truth<br>✅ No duplication<br>✅ Impossible for modules to drift<br>✅ Common module is independently testable<br>✅ Simpler root callers<br>❌ Slightly more complex initial setup |
| **Four-module architecture** | Add separate data-sources module | ❌ Over-engineered<br>❌ Additional complexity with minimal benefit |

**Decision**: Implement three-module architecture with common module centralizing all shared logic

**Summary**: The common module became the "brain" of the infrastructure, containing all variable definitions (with defaults), Key Vault data sources, and naming patterns. Foundation and workloads became thin wrappers that simply call common and use its outputs.

**Implementation**:

### Module 1: Common (`modules/common/`)
**Centralizes everything shared:**
- `variables.tf` - ALL variable definitions with defaults (environment, location, org_name, common_tags)
- `naming.tf` - CAF naming patterns (resource_type_map, naming_patterns)
- `data-sources.tf` - Key Vault data sources (fetches subscription IDs)
- `outputs.tf` - Exposes naming_patterns, subscription IDs, tenant_id, all variables

**Key insight**: Environment variable defaults to "" for foundation (no environment suffix in MG names)

### Module 2: Foundation (`modules/foundation/`)
**Minimal - just MG logic:**
- `main.tf` - Management groups
- `subscriptions.tf` - Subscription associations
- `variables.tf` - Type declarations only (no defaults) - receives from parent
- `outputs.tf` - MG IDs and names

**No data sources, no variable defaults - everything from common module**

### Module 3: Workloads (`modules/workloads/`)
**Minimal - just RG logic:**
- `main.tf` - Resource groups
- `variables.tf` - Type declarations only (no defaults) - receives from parent
- `outputs.tf` - RG IDs and names

**No data sources, no variable defaults - everything from common module**

### Root Callers

**Foundation (`foundation/`):**
```hcl
# No variables.tf - uses common module defaults
# No data-sources.tf - common module fetches from Key Vault
# No .tfvars files - no environment variants

# main.tf
module "common" {
  source = "../modules/common"
  environment = ""  # Foundation doesn't use environment
}

module "foundation" {
  source = "../modules/foundation"
  naming_patterns = module.common.naming_patterns
  tenant_id = module.common.tenant_id
  hq_subscription_id = module.common.hq_subscription_id
  # ...
}
```

**Workloads (`workloads/`):**
```hcl
# Minimal variables.tf - just environment override
# No data-sources.tf - common module fetches from Key Vault

# main.tf
module "common" {
  source = "../modules/common"
  environment = var.environment  # Set per .tfvars
}

module "workloads" {
  source = "../modules/workloads"
  naming_patterns = module.common.naming_patterns
  location = module.common.location
  common_tags = module.common.common_tags
}
```

**Benefits**:

1. **DRY Principle**: Zero duplication of variables, naming logic, or data sources
2. **Single Source of Truth**: Common module is authoritative for all shared configuration
3. **Impossible to Drift**: Foundation and workloads can't have different naming schemes or variable defaults
4. **Testability**: Common module can be tested independently with `terraform console`
5. **Simplicity**: Root callers are extremely simple - just call common and pass outputs
6. **Maintainability**: Update naming/variables once in common, all modules benefit
7. **Scalability**: Easy to add new modules (networking, monitoring) that reuse common
8. **Clear Architecture**: Dependency flow is explicit and unidirectional

**Module Dependencies**:
```
foundation/              workloads/
    ↓                        ↓
    └─────→ modules/common ←─┘

(No dependency between foundation and workloads)
```

**Variable Flow**:
```
User .tfvars → workloads/variables.tf → modules/common/variables.tf (defaults)
                                              ↓
                                       All modules use common outputs
```

**Rationale**: Discovered during implementation that having variable definitions in both common and child modules violated DRY. Centralizing everything in common module eliminated duplication and made the architecture much cleaner. Foundation doesn't even need variables.tf since it uses all defaults from common.

---

**Next Steps**:
See [NEXT_STEPS.md](NEXT_STEPS.md) for detailed implementation plan including:
1. Infrastructure preparation (Key Vault, Storage Account)
2. Code refactoring into modules
3. State migration from monolithic to modular
4. Testing and validation
5. Rollout to all environments (dev, stage, prod)
