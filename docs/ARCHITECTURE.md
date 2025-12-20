# A10 Corp Azure Infrastructure - Architecture

**Last Updated**: 2025-12-20
**Repository**: [github.com:amaramdotme/A10_Corp-terraform.git](https://github.com/amaramdotme/A10_Corp-terraform.git) (private)
**Terraform**: >= 1.0 | **Azure Provider**: ~> 4.0

---

## Overview

Enterprise Terraform infrastructure managing Azure Management Groups, Subscriptions, Resource Groups, Networking, and Container Registries using a three-module architecture following Azure Cloud Adoption Framework (CAF) standards.

### Three-Module Design

1. **Common** - Shared naming, variables, Key Vault, and Storage integration (library)
2. **Foundation** - Management Groups + subscription associations + Global ACR (global, deploy once)
3. **Workloads** - Resource Groups + VNets + Subnets + Identity per environment (deploy/destroy as needed)

---

## Current Infrastructure

### Hierarchy

```
Tenant Root Group
├── sub-root (Infrastructure subscription)
│   └── rg-root-iac
│       ├── kv-root-terraform (Secrets & Config)
│       ├── storerootblob (Terraform State)
│       └── acra10corpsales ✅ FOUNDATION (Global ACR)
│
└── mg-a10corp-hq ✅ FOUNDATION
    ├── sub-hq → rg-a10corp-shared-dev ✅
    ├── mg-a10corp-sales ✅
    │   └── sub-sales → rg-a10corp-sales-dev ✅
    │       ├── vnet-a10corp-sales-dev ✅
    │       │   ├── snet-a10corp-sales-dev-aks-nodes ✅
    │       │   └── snet-a10corp-sales-dev-ingress ✅
    │       └── id-a10corp-sales-dev ✅ (Managed Identity)
    └── mg-a10corp-service ✅
        └── sub-service → rg-a10corp-service-dev ✅
```

### Deployment Status

| Component | Status | Resources | State File |
|-----------|--------|-----------|------------|
| **Pre-Terraform** (manual) | ✅ Complete | rg-root-iac, kv-root-terraform, storerootblob | N/A |
| **Foundation** | ✅ Deployed | 3 MGs + 3 associations + ACR | storerootblob/foundation |
| **Workloads (Dev)** | ✅ Deployed 2025-12-20 | 3 RGs + VNet + Subnets + Identity | storerootblob/workloads-dev |
| **Workloads (Stage)** | ⏳ Pending | 0/3 resource groups | storerootblob/workloads-stage |
| **Workloads (Prod)** | ⏳ Pending | 0/3 resource groups | storerootblob/workloads-prod |
| **CI/CD (OIDC)** | ✅ Configured | 4 federated credentials + 6 RBAC roles | [OIDC_SETUP.md](OIDC_SETUP.md) |

---

## Project Structure

```
 terraform_iac/
├── foundation/                 # Foundation root (GLOBAL)
│   ├── main.tf                 # Calls common + foundation modules
│   ├── registry.tf             # Global ACR definition
│   ├── backend.tf              # Remote state: storerootblob/foundation
│   └── environments/backend.hcl
│
├── workloads/                  # Workloads root (PER-ENVIRONMENT)
│   ├── main.tf                 # Calls common + workloads modules (ACR ID constructed here)
│   ├── backend.tf              # Remote state: storerootblob/workloads-{env}
│   ├── variables.tf            # Environment overrides
│   └── environments/
│       ├── dev.tfvars, stage.tfvars, prod.tfvars
│       └── backend-dev.hcl, backend-stage.hcl, backend-prod.hcl
│
├── modules/
│   ├── common/                 # Naming, variables, Key Vault (shared library)
│   │   ├── naming.tf           # Three-branch CAF naming logic
│   │   ├── variables.tf        # All variable definitions (parameterized root)
│   │   ├── data-sources.tf     # Key Vault & Storage data sources
│   │   └── outputs.tf          # Exports naming_patterns, subscription IDs, root constants
│   ├── foundation/             # Management groups module
│   │   ├── main.tf             # Management group resources
│   │   └── subscriptions.tf    # Subscription associations
│   └── workloads/              # Resource groups module
│       ├── main.tf             # Resource group resources
│       ├── networking.tf       # VNet & Subnets resources
│       └── identity.tf         # Managed Identity & RBAC
│
├── docs/                       # Documentation (Consolidated)
│   ├── ARCHITECTURE.md         # This file
│   ├── DECISIONS.md            # Architectural Decision Records
│   ├── NEXTSTEPS.md            # Priorities + parking lot
│   ├── OIDC_SETUP.md           # OIDC configuration guide
│   └── USER_MANUAL.md          # Operator guide
│
├── init-plan-apply.sh          # Helper script (dynamic backend injection)
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
| Virtual Network | `vnet-{org}-{workload}-{env}` | `vnet-a10corp-sales-dev` |
| Managed Identity | `id-{org}-{workload}-{env}` | `id-a10corp-sales-dev` |

### No-Hyphen Resources (alphanumeric only)

| Resource | Pattern | Example |
|----------|---------|---------|
| Storage Account | `st{org}{workload}{env}` | `sta10corpsalesdev` |
| Container Registry| `acr{org}{workload}` | `acra10corpsales` |

**Implementation**: [modules/common/naming.tf](../modules/common/naming.tf)

---

## Security & Secrets

### Parameterized Root Infrastructure
The management resources (`rg-root-iac`, `kv-root-terraform`, `storerootblob`) are no longer hardcoded. They are passed as required variables:
- `TF_VAR_root_resource_group_name`
- `TF_VAR_root_key_vault_name`
- `TF_VAR_root_storage_account_name`

### Decoupling (ID Construction)
To prevent plan-time deadlocks in CI/CD, the Workloads module does not query Azure for the ACR ID via data sources. Instead, it **constructs** the ID string using interpolation, allowing Foundation and Workloads to be proposed in a single PR.

### Environment Tagging
All resources are automatically tagged with an `Environment` tag:
- **Foundation Resources**: `Environment = global`
- **Workload Resources**: `Environment = dev|stage|prod`

This is managed centrally in `modules/common/outputs.tf`.

---

## Quick Start

### Prerequisites

- Terraform >= 1.0
- Azure CLI authenticated (`az login`)
- Updated `.env` file with `TF_VAR_root_*` variables

### Deployment via Helper Script

The helper script handles dynamic backend configuration injection automatically.

```bash
# 1. Deploy Foundation (Global)
./init-plan-apply.sh --foundation init
./init-plan-apply.sh --foundation plan
./init-plan-apply.sh --foundation apply

# 2. Deploy Workloads (e.g. Dev)
./init-plan-apply.sh --workloads --env dev init
./init-plan-apply.sh --workloads --env dev plan
./init-plan-apply.sh --workloads --env dev apply
```

---

## Terraform Commands

### Dynamic Backend Initialization
Backend configurations are injected during `init`:
```bash
terraform init \
  -backend-config="resource_group_name=${TF_VAR_root_resource_group_name}" \
  -backend-config="storage_account_name=${TF_VAR_root_storage_account_name}" \
  -backend-config="environments/backend.hcl"
```

---

## Troubleshooting

### `Error: MissingSubscriptionRegistration`
**Fix**: Provider registration is now automatic. Ensure the service principal has `Contributor` or `Classic Administrator` permissions at the subscription level to allow namespace registration.

### `Error: State Lock`
**Fix**: Use `terraform force-unlock <ID>` if a previous run was interrupted.

---

## Reference Links

- **Architecture Decisions**: [DECISIONS.md](DECISIONS.md)
- **OIDC Setup Guide**: [OIDC_SETUP.md](OIDC_SETUP.md)
- **User Manual**: [USER_MANUAL.md](USER_MANUAL.md)
- **Azure CAF**: https://learn.microsoft.com/azure/cloud-adoption-framework/

