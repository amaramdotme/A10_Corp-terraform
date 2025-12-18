# A10 Corp Azure Infrastructure - Architecture

**Last Updated**: 2025-12-18
**Repository**: [github.com:amaramdotme/A10_Corp-terraform.git](https://github.com/amaramdotme/A10_Corp-terraform.git) (private)
**Terraform**: >= 1.0 | **Azure Provider**: ~> 4.0

---

## Overview

Enterprise Terraform infrastructure managing Azure Management Groups, Subscriptions, and Resource Groups using a three-module architecture following Azure Cloud Adoption Framework (CAF) standards.

### Three-Module Design

1. **Common** - Shared naming, variables, Key Vault integration (library)
2. **Foundation** - Management Groups + subscription associations (global, deploy once)
3. **Workloads** - Resource Groups per environment (deploy/destroy as needed)

---

## Current Infrastructure

### Hierarchy

```
Tenant Root Group
├── sub-root (Infrastructure subscription)
│   └── rg-root-iac
│       ├── kv-root-terraform (9 secrets)
│       └── storerootblob (4 state containers)
│
└── mg-a10corp-hq ✅ FOUNDATION
    ├── sub-hq → rg-a10corp-shared-dev ✅ (stage/prod ⏳)
    ├── mg-a10corp-sales ✅
    │   └── sub-sales → rg-a10corp-sales-dev ✅ (stage/prod ⏳)
    └── mg-a10corp-service ✅
        └── sub-service → rg-a10corp-service-dev ✅ (stage/prod ⏳)
```

### Deployment Status

| Component | Status | Resources | State File |
|-----------|--------|-----------|------------|
| **Pre-Terraform** (manual) | ✅ Complete | rg-root-iac, kv-root-terraform, storerootblob | N/A |
| **Foundation** | ✅ Deployed | 3 MGs + 3 associations | storerootblob/foundation |
| **Workloads (Dev)** | ✅ Deployed 2025-12-17 | 3 resource groups | storerootblob/workloads-dev |
| **Workloads (Stage)** | ⏳ Pending | 0/3 resource groups | storerootblob/workloads-stage |
| **Workloads (Prod)** | ⏳ Pending | 0/3 resource groups | storerootblob/workloads-prod |
| **CI/CD (OIDC)** | ✅ Configured 2025-12-18 | 4 federated credentials + 6 RBAC roles | [OIDC_SETUP.md](OIDC_SETUP.md) |

### Management Group IDs

- `mg-a10corp-hq`: a56fd357-2ecc-46bf-b831-1b86e5fd43bb
- `mg-a10corp-sales`: 3ad4b4c9-368c-44c9-8f02-df14e0da8447
- `mg-a10corp-service`: 4b511fa7-48ad-495e-b7d7-bf6cfdc8a22e

### Subscriptions (4 total)

| Name | Purpose | Management Group | Status |
|------|---------|------------------|--------|
| sub-root | Infrastructure (Key Vault, Storage) | Tenant Root (never moved) | ✅ Active |
| sub-hq | HQ workloads | mg-a10corp-hq | ✅ Associated |
| sub-sales | Sales workloads | mg-a10corp-sales | ✅ Associated |
| sub-service | Service workloads | mg-a10corp-service | ✅ Associated |

---

## Project Structure

```
terraform_iac/
├── foundation/                 # Foundation root (GLOBAL)
│   ├── main.tf                 # Calls common + foundation modules
│   ├── backend.tf              # Remote state: storerootblob/foundation-dev
│   └── environments/backend.hcl
│
├── workloads/                  # Workloads root (PER-ENVIRONMENT)
│   ├── main.tf                 # Calls common + workloads modules
│   ├── backend.tf              # Remote state: storerootblob/workloads-{env}
│   ├── variables.tf            # Environment override
│   └── environments/
│       ├── dev.tfvars, stage.tfvars, prod.tfvars
│       └── backend-dev.hcl, backend-stage.hcl, backend-prod.hcl
│
├── modules/
│   ├── common/                 # Naming, variables, Key Vault (shared library)
│   │   ├── naming.tf           # Three-branch CAF naming logic
│   │   ├── variables.tf        # All variable definitions with defaults
│   │   ├── data-sources.tf     # Key Vault data sources
│   │   └── outputs.tf          # Exports naming_patterns, subscription IDs
│   ├── foundation/             # Management groups module
│   │   ├── main.tf             # Management group resources
│   │   └── subscriptions.tf    # Subscription associations
│   └── workloads/              # Resource groups module
│       └── main.tf             # Resource group resources
│
├── ARCHITECTURE.md             # This file (infrastructure + commands)
├── DECISIONS.md                # Architectural Decision Records
├── NEXTSTEPS.md                # Priorities + parking lot
├── CLAUDE.md                   # AI assistant context
├── .env.example                # Environment variable template
└── .gitignore
```

---

## Naming Convention (CAF-Compliant)

### Standard Resources (with hyphens)

| Resource | Pattern | Example |
|----------|---------|---------|
| Management Group | `mg-{org}-{workload}` | `mg-a10corp-sales` |
| Resource Group | `rg-{org}-{workload}-{env}` | `rg-a10corp-sales-dev` |
| Virtual Machine | `vm-{org}-{workload}-{env}` | `vm-a10corp-sales-dev` |

### No-Hyphen Resources (alphanumeric only)

| Resource | Pattern | Example |
|----------|---------|---------|
| Storage Account | `st{org}{workload}{env}` | `sta10corpsalesdev` |

**Implementation**: [modules/common/naming.tf](modules/common/naming.tf) - Three-branch naming system handles hyphens, no-hyphens, and environment suffixes

**Details**: See [DECISIONS.md - Decision 16](DECISIONS.md#decision-16-three-branch-naming-system-for-azure-resource-restrictions)

---

## Security & Secrets

### Key Vault Integration

**Native Terraform approach** - No external scripts:

```hcl
data "azurerm_key_vault_secret" "hq_subscription_id" {
  name         = "terraform-${var.environment}-hq-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}
```

### Secret Structure

```
kv-root-terraform/
# 9 secrets (3 subscription IDs × 3 environments)
├── terraform-dev-hq-sub-id
├── terraform-dev-sales-sub-id
├── terraform-dev-service-sub-id
├── terraform-stage-* (same pattern)
└── terraform-prod-* (same pattern)
```

**Note**: Tenant ID and root subscription ID from authenticated context (`.env` file or GitHub OIDC), not Key Vault.

### Authentication

**Local Development**: Azure CLI + .env file
```bash
export ARM_SUBSCRIPTION_ID="<sub-root-id>"  # Where Key Vault lives
export ARM_TENANT_ID="<tenant-id>"
```

**CI/CD**: OIDC Workload Identity Federation (zero long-lived secrets) - See [DECISIONS.md - Decision 9](DECISIONS.md#decision-9-cicd-authentication-method)

---

## Quick Start

### Prerequisites

- Terraform >= 1.0 at `~/bin/terraform`
- Azure CLI authenticated (`az login`)
- Permissions: Management Group Contributor, Key Vault Secrets Officer, Contributor on subscriptions

### 5-Minute Deploy

```bash
# 1. Clone and setup
git clone git@github.com:amaramdotme/A10_Corp-terraform.git
cd A10_Corp-terraform
cp .env.example .env
nano .env  # Update ARM_SUBSCRIPTION_ID and ARM_TENANT_ID

# 2. Deploy Foundation (Management Groups)
cd foundation/
source ../.env
terraform init
terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan

# 3. Deploy Workloads (Resource Groups - Dev)
cd ../workloads/
source ../.env
terraform init -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

---

## Terraform Commands

### The Three Switches

**Foundation (2/3)**:
1. `source .env` ✓ Always required
2. Backend config ✓ `environments/backend.hcl`
3. Var-file ✗ NOT used (global)

**Workloads (3/3)**:
1. `source .env` ✓ Always required
2. Backend config ✓ `environments/backend-{env}.hcl`
3. Var-file ✓ `environments/{env}.tfvars`

================================================================================
TERRAFORM COMMANDS - THREE-MODULE ARCHITECTURE
================================================================================

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

--- Outputs ---
terraform output
terraform output -json > workloads-outputs.json
terraform output resource_groups

--- Destroy ---
source ../.env && terraform destroy -var-file="environments/dev.tfvars"

###### WORKLOADS ENDS ######

### Common Commands

```bash
# Format & validate
terraform fmt -recursive
terraform validate

# State management
terraform state list
terraform state show <resource>
terraform state pull > backup-$(date +%Y%m%d).json

# Import existing resource
terraform import module.workloads.azurerm_resource_group.sales \
  /subscriptions/<SUB_ID>/resourceGroups/rg-a10corp-sales-dev

# Force unlock stuck state
terraform force-unlock <LOCK_ID>
```

---

## Troubleshooting

### `Error: subscription ID could not be determined`
**Fix**: Source .env file before running terraform
```bash
source .env
terraform plan
```

### `Error: authorization failed for Key Vault`
**Fix**: Grant Key Vault Secrets Officer role
```bash
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee $(az ad signed-in-user show --query mail -o tsv) \
  --scope /subscriptions/<SUB_ID>/resourceGroups/rg-root-iac/providers/Microsoft.KeyVault/vaults/kv-root-terraform
```

### Wrong environment deployed
**Fix**: Always use matching backend config + var-file
```bash
# Dev
terraform init -reconfigure -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars"
```

### State lock timeout
**Fix**: Verify no other terraform process running, then force unlock
```bash
terraform force-unlock <LOCK_ID>
```

---

## Key Features

### ✅ Implemented

- Three-Module Architecture (Common + Foundation + Workloads)
- Three-Branch Naming System (hyphens, no-hyphens, environment suffixes)
- Native Key Vault Integration (no external scripts)
- Multi-Environment Support (dev, stage, prod)
- Remote State Backend (Azure Storage with locking)
- Zero Secrets in Git (Key Vault + environment variables)

### 📊 Infrastructure Stats

- **Modules**: 3 (Common, Foundation, Workloads)
- **Management Groups**: 3 deployed ✅
- **Subscription Associations**: 3 deployed ✅
- **Resource Groups**: 3/9 deployed (dev ✅, stage/prod ⏳)
- **Key Vault Secrets**: 9 (3 subscription IDs × 3 environments)
- **State Files**: 4 (1 foundation + 3 workloads)
- **CI/CD Authentication**: OIDC ✅ (4 environments: global, dev, stage, prod)

---

## Reference Links

- **Architecture Decisions**: [DECISIONS.md](DECISIONS.md)
- **Next Steps**: [NEXTSTEPS.md](NEXTSTEPS.md)
- **AI Context**: [CLAUDE.md](CLAUDE.md)
- **OIDC Setup Guide**: [OIDC_SETUP.md](OIDC_SETUP.md)
- **Azure CAF**: https://learn.microsoft.com/azure/cloud-adoption-framework/
- **Terraform azurerm**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure Management Groups**: https://learn.microsoft.com/azure/governance/management-groups/

---

**Last Updated**: 2025-12-18
**License**: Private - All Rights Reserved
