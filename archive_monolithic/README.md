# Archived Monolithic Structure

This directory contains the **original monolithic Terraform structure** before the three-module architecture refactoring.

## Archive Date
2025-12-17

## What's Here

### Original Root-Level Files
- `data-sources.tf` - Key Vault data sources (now in `modules/common/data-sources.tf`)
- `naming.tf` - CAF naming logic (now in `modules/common/naming.tf`)
- `variables.tf` - Variable declarations (now in `modules/common/variables.tf`)
- `providers.tf` - Provider configuration (split into `foundation/providers.tf` and `workloads/providers.tf`)
- `management-groups.tf` - Management group resources (now in `modules/foundation/main.tf`)
- `subscriptions.tf` - Subscription associations (now in `modules/foundation/subscriptions.tf`)
- `resource-groups.tf` - Resource group resources (now in `modules/workloads/main.tf`)
- `outputs.tf` - Output values (split across module outputs)
- `imports.tf` - Import blocks for existing resources

### Original Environments Directory
- `environments/dev.tfvars` - Development environment config (now in `workloads/environments/dev.tfvars`)
- `environments/stage.tfvars` - Staging environment config
- `environments/prod.tfvars` - Production environment config
- `environments/README.md` - Original environments documentation

## Why Archived?

The monolithic structure was refactored into a **three-module architecture** to:

1. **Separate concerns**: Foundation (rarely changes) vs Workloads (frequent changes)
2. **Eliminate duplication**: Common module centralizes all shared configuration
3. **Enable independent deployments**: Foundation and workloads can be deployed separately
4. **Support dual CI/CD workflows**: Separate GitHub Actions workflows for foundation and workloads
5. **Reduce blast radius**: Changes to workloads don't risk foundation infrastructure

## New Structure

```
terraform_iac/
├── modules/
│   ├── common/       # THE BRAIN - centralized config
│   ├── foundation/   # Management groups module
│   └── workloads/    # Resource groups module
├── foundation/       # Foundation root caller (single deployment)
├── workloads/        # Workloads root caller (per-environment deployments)
└── archive_monolithic/  # ← You are here
```

See [Decision 15](../docs/DECISIONS.md) for full architectural rationale.

## Do Not Use

These files are **archived for reference only**. Do not use them for deployments.

All new deployments should use:
- `foundation/` for management groups
- `workloads/` for resource groups

## Restoration

If you need to restore the monolithic structure:
1. Move files back to repository root
2. Delete the new module structure
3. Run `terraform init` from repository root

**Note**: This is not recommended unless absolutely necessary.
