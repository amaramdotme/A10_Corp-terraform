# Azure Environment Information

## Subscription Structure

### Root/Shared Subscription
- **Purpose**: Shared/common resources across A10 Corp
- **State**: Enabled
- **Is Default**: true

### Sales Subscription
- **Purpose**: Dedicated subscription for Sales workloads
- **State**: Enabled

### Service Subscription
- **Purpose**: Dedicated subscription for Service workloads
- **State**: Enabled
- **Note**: Previously named "marketing", renamed to "service" for consistency

## Authentication

- **Environment**: AzureCloud
- **Subscription IDs, Tenant IDs**: Stored in `.tfvars` files (not committed to git) and GitHub Secrets for CI/CD

## Target Architecture

### Management Group Hierarchy

```
Tenant Root Group
└── mg-a10corp-hq (A10 Corporation HQ)
    ├── Associated Subscription: Shared
    ├── mg-a10corp-sales (Sales Business Unit)
    │   └── Associated Subscription: Sales
    └── mg-a10corp-service (Service Business Unit)
        └── Associated Subscription: Service
```

### Resource Groups (Multi-Environment)

Per environment (dev, stage, prod), the following resource groups are created:

- **Shared Subscription**:
  - `rg-a10corp-shared-{env}` (e.g., `rg-a10corp-shared-dev`)

- **Sales Subscription**:
  - `rg-a10corp-sales-{env}` (e.g., `rg-a10corp-sales-dev`)

- **Service Subscription**:
  - `rg-a10corp-service-{env}` (e.g., `rg-a10corp-service-dev`)

**Current Deployment Status**: 🔴 All infrastructure destroyed (2025-12-17)

### Deployed Components

**Infrastructure Status**: All Terraform-managed resources have been destroyed.

**What was destroyed:**
1. **Management Groups** ❌:
   - `mg-a10corp-hq` (A10 Corporation HQ management group)
   - `mg-a10corp-sales` (Sales business unit)
   - `mg-a10corp-service` (Service business unit)

2. **Subscription Associations** ❌:
   - All subscriptions moved back to Tenant Root Group automatically

3. **Resource Groups (Dev Environment)** ❌:
   - `rg-a10corp-shared-dev` (was in eastus, shared subscription)
   - `rg-a10corp-sales-dev` (was in eastus, sales subscription)
   - `rg-a10corp-service-dev` (was in eastus, service subscription)

**What still exists:**
- ✅ All Azure subscriptions (billing accounts preserved)
- ✅ Terraform configuration code (ready to redeploy)

### Naming Convention

Following Azure Cloud Adoption Framework (CAF) standards:
- **Management Groups**: `mg-{org}-{workload}` (e.g., `mg-a10corp-sales`)
  - No environment suffix (management groups are environment-agnostic)
- **Resource Groups**: `rg-{org}-{workload}-{env}` (e.g., `rg-a10corp-sales-dev`)
  - Includes environment suffix (dev/stage/prod)
- **Delimiter**: Hyphen (-) for readability
- **Case**: Lowercase for consistency

**Implementation**: All naming logic is centralized in [terraform/naming.tf](terraform/naming.tf) using Terraform locals. Access pattern: `local.naming_patterns["azurerm_resource_group"]["sales"]`

## Notes

- This subscription is currently set as the default subscription for Azure CLI operations
- All Terraform deployments will use this subscription unless otherwise specified
