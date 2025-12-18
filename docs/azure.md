# Azure Environment Information

**Last Updated**: 2025-12-17
**Architecture**: Three-module (Common + Foundation + Workloads)
**Repository**: [github.com:amaramdotme/A10_Corp-terraform.git](https://github.com/amaramdotme/A10_Corp-terraform.git) (private)

---

## Current Deployment Status

### ✅ Pre-Terraform Infrastructure (Manual Setup - Complete)

**Purpose**: Infrastructure to support Terraform itself (never managed by Terraform)

**Location**: Azure Portal (manual creation)

**Resources**:
- **Resource Group**: `rg-root-iac` (in sub-root subscription)
- **Key Vault**: `kv-root-terraform` (actual deployed name)
  - Public network access: Enabled
  - RBAC: User assigned "Key Vault Secrets Officer" role at RG level
  - Secrets: 9 total (3 per environment: `terraform-{env}-hq-sub-id`, `terraform-{env}-sales-sub-id`, `terraform-{env}-service-sub-id`)
- **Storage Account**: `storerootblob` (actual deployed name)
  - SKU: Standard_LRS
  - Blob versioning: Enabled
  - Soft delete: Enabled (7 days)
  - Containers: `foundation-dev`, `workloads-dev`, `workloads-stage`, `workloads-prod`

---

### ✅ Foundation Module (Deployed - Global)

**Terraform-Managed Resources**: 7 resources deployed

**Deployment Date**: 2025-12-17
**State File**: `storerootblob/foundation-dev/terraform.tfstate`
**Module**: `foundation/`

**Resources Deployed**:
1. ✅ **Management Group**: `mg-a10corp-hq`
   - ID: `a56fd357-2ecc-46bf-b831-1b86e5fd43bb`
   - Parent: Tenant Root Group

2. ✅ **Management Group**: `mg-a10corp-sales`
   - ID: `3ad4b4c9-368c-44c9-8f02-df14e0da8447`
   - Parent: `mg-a10corp-hq`

3. ✅ **Management Group**: `mg-a10corp-service`
   - ID: `4b511fa7-48ad-495e-b7d7-bf6cfdc8a22e`
   - Parent: `mg-a10corp-hq`

4. ✅ **Subscription Association**: `sub-hq` → `mg-a10corp-hq`
5. ✅ **Subscription Association**: `sub-sales` → `mg-a10corp-sales`
6. ✅ **Subscription Association**: `sub-service` → `mg-a10corp-service`
7. ✅ **Validation Resource**: `null_resource.validate_caf_naming`

**Management Group Hierarchy** (Current State):
```
Tenant Root Group
├── sub-root (stays here, never moved)
└── mg-a10corp-hq (a56fd357-2ecc-46bf-b831-1b86e5fd43bb) ✅
    ├── sub-hq associated ✅
    ├── mg-a10corp-sales (3ad4b4c9-368c-44c9-8f02-df14e0da8447) ✅
    │   └── sub-sales associated ✅
    └── mg-a10corp-service (4b511fa7-48ad-495e-b7d7-bf6cfdc8a22e) ✅
        └── sub-service associated ✅
```

---

### ⏳ Workloads Module (Not Yet Deployed)

**Status**: Code ready, deployment pending
**Module**: `workloads/`
**Environments**: dev, stage, prod

**Resource Groups to be Created** (per environment):
- `rg-a10corp-shared-{env}` in sub-hq
- `rg-a10corp-sales-{env}` in sub-sales
- `rg-a10corp-service-{env}` in sub-service

**Example for dev environment**:
- `rg-a10corp-shared-dev` → sub-hq (eastus)
- `rg-a10corp-sales-dev` → sub-sales (eastus)
- `rg-a10corp-service-dev` → sub-service (eastus)

---

## Azure Subscriptions (4 Total)

| Subscription | Purpose | Management Group | Status |
|--------------|---------|------------------|--------|
| **sub-root** | Root subscription (hosts Key Vault & Storage) | Tenant Root MG (never moved) | ✅ Active |
| **sub-hq** | HQ subscription | mg-a10corp-hq | ✅ Associated |
| **sub-sales** | Sales subscription | mg-a10corp-sales | ✅ Associated |
| **sub-service** | Service subscription | mg-a10corp-service | ✅ Associated |

**Security Note**: Subscription IDs are stored in Azure Key Vault (`kv-root-terraform`) and fetched via Terraform data sources. Zero sensitive values in git repository.

---

## Naming Convention

Following Azure Cloud Adoption Framework (CAF) standards:

### Standard Resources (with hyphens)
- **Management Groups**: `mg-{org}-{workload}` (e.g., `mg-a10corp-sales`)
  - No environment suffix (management groups are global)
- **Resource Groups**: `rg-{org}-{workload}-{env}` (e.g., `rg-a10corp-sales-dev`)
  - Includes environment suffix (dev/stage/prod)

### No-Hyphen Resources (alphanumeric only)
- **Storage Accounts**: `st{org}{workload}{env}` (e.g., `sta10corpsalesdev`)
  - Azure requirement: alphanumeric only, no hyphens

**Implementation**: All naming logic centralized in [modules/common/naming.tf](../modules/common/naming.tf) using three-branch naming system (see [DECISIONS.md - Decision 16](DECISIONS.md#decision-16-three-branch-naming-system-for-azure-resource-restrictions)).

**Access Pattern**: `local.naming_patterns["azurerm_resource_group"]["sales"]`

---

## Authentication

### Local Development
- **Method**: Azure CLI (`az login`)
- **Environment Variables**: `.env` file (gitignored)
  - `ARM_SUBSCRIPTION_ID`: sub-root (where Key Vault lives)
  - `ARM_TENANT_ID`: Tenant ID

### CI/CD (GitHub Actions)
- **Method**: OIDC Workload Identity Federation (no long-lived secrets)
- **Provider**: `azure/login@v1` action
- **Secrets**: Non-sensitive IDs only (client ID, tenant ID, subscription ID)
- **Benefits**: Zero secrets in GitHub, tokens expire automatically

See [DECISIONS.md - Decision 9](DECISIONS.md#decision-9-cicd-authentication-method) for OIDC implementation details.

---

## State Management

### Foundation
- **Backend**: Azure Storage (`storerootblob`)
- **Container**: `foundation-dev`
- **State File**: `terraform.tfstate`
- **Locking**: Enabled via Azure Storage lease

### Workloads
- **Backend**: Azure Storage (`storerootblob`)
- **Containers**: `workloads-dev`, `workloads-stage`, `workloads-prod`
- **State Files**: 3 separate files (one per environment)
- **Locking**: Enabled via Azure Storage lease

---

## Next Steps

1. ⏳ **Deploy Workloads Module** (dev environment)
2. ⏳ Test workloads deployment in dev
3. ⏳ Promote to stage environment
4. ⏳ Promote to prod environment

---

## References

- [Architecture Decisions](DECISIONS.md)
- [Terraform Commands](TERRAFORM_COMMANDS.md)
- [Foundation Module README](../foundation/README.md)
- [Workloads Module README](../workloads/README.md)
- [Session History](sessions/)
