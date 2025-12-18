# A10 Corp Azure Infrastructure - Terraform IaC

Enterprise-grade Terraform Infrastructure as Code for managing Azure Management Groups, Subscriptions, and Resource Groups with native Key Vault integration and three-module architecture.

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue?logo=microsoftazure)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-Private-red)]()

---

## 📖 What This Does

This repository manages A10 Corporation's Azure infrastructure using Terraform with a three-module architecture:

1. **Common Module** - Shared naming logic, variables, and Key Vault integration (reusable library)
2. **Foundation Module** - Management Groups and subscription associations (deploy once, rarely change)
3. **Workloads Module** - Resource Groups per environment (deploy/destroy as needed)

The infrastructure follows Azure Cloud Adoption Framework (CAF) standards with hierarchical management groups, automated subscription placement, and isolated resource containers for dev, stage, and production environments.

---

## 🏗️ Architecture Overview

```
Tenant Root Group
├── sub-root (Infrastructure subscription - stays in root)
│   └── rg-root-iac (Key Vault + Storage Account)
│
└── mg-a10corp-hq ✅ FOUNDATION MODULE
    ├── sub-hq → rg-a10corp-shared-{env} ⏳ WORKLOADS MODULE
    ├── mg-a10corp-sales ✅
    │   └── sub-sales → rg-a10corp-sales-{env} ⏳
    └── mg-a10corp-service ✅
        └── sub-service → rg-a10corp-service-{env} ⏳
```

**Current Status** (as of 2025-12-17):
- ✅ **Foundation**: 3 Management Groups + 3 Subscription Associations deployed
- ⏳ **Workloads**: Resource Groups not yet deployed (code ready)

For detailed architecture decisions, see [docs/DECISIONS.md](docs/DECISIONS.md).

---

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.0 installed at `~/bin/terraform`
- **Azure CLI** authenticated (`az login`)
- **Azure Permissions**:
  - Management Group Contributor (tenant level)
  - Key Vault Secrets Officer (on `kv-root-terraform`)
  - Contributor (on target subscriptions)

### 5-Minute Setup

```bash
# 1. Clone and navigate
git clone git@github.com:amaramdotme/A10_Corp-terraform.git
cd A10_Corp-terraform

# 2. Authenticate to Azure
az login

# 3. Create .env file from template
cp .env.example .env
nano .env  # Update ARM_SUBSCRIPTION_ID and ARM_TENANT_ID (from: az account show)

# 4. Deploy Foundation (Management Groups)
cd foundation/
source ../.env
terraform init
terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan

# 5. Deploy Workloads (Resource Groups - Dev)
cd ../workloads/
source ../.env
terraform init -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

**Next Steps**: See [foundation/README.md](foundation/README.md) and [workloads/README.md](workloads/README.md) for detailed deployment guides.

---

## 📋 Documentation Index

### Getting Started
- **[Quick Start](#quick-start)** - 5-minute setup guide (above)
- **[Foundation Deployment](foundation/README.md)** - Deploy management groups
- **[Workloads Deployment](workloads/README.md)** - Deploy resource groups

### Reference
- **[Terraform Commands](docs/TERRAFORM_COMMANDS.md)** - Complete command reference
- **[Architecture Decisions](docs/DECISIONS.md)** - Why we built it this way
- **[Azure Resources](docs/azure.md)** - Current infrastructure inventory

### Advanced
- **[CLAUDE.md](CLAUDE.md)** - AI assistant context and session handoff
- **[Module Documentation](modules/)** - Common, Foundation, and Workloads modules
- **[Session History](docs/sessions/)** - Development timeline

---

## 🎯 Key Features

### ✅ Implemented

- ✅ **Three-Module Architecture** - Common + Foundation + Workloads (Decision 15)
- ✅ **Three-Branch Naming System** - Handles hyphens, no-hyphens, and environment suffixes (Decision 16)
- ✅ **Native Key Vault Integration** - Direct Terraform data sources, no scripts (Decision 14)
- ✅ **Multi-Environment Support** - Dev, Stage, Production via `.tfvars` files
- ✅ **OIDC Authentication** - GitHub Actions with no long-lived secrets (Decision 9)
- ✅ **Remote State Backend** - Azure Storage with separate containers per module
- ✅ **Zero Secrets in Git** - All sensitive values in Key Vault or environment variables

### 📊 Infrastructure Stats

- **Modules**: 3 (Common, Foundation, Workloads)
- **Management Groups**: 3 (deployed ✅)
- **Subscription Associations**: 3 (deployed ✅)
- **Resource Groups**: 9 total (3 per environment, pending ⏳)
- **Key Vault Secrets**: 9 (3 subscription IDs × 3 environments)
- **Terraform State Files**: 4 (1 foundation + 3 workloads)

---

## 🏷️ Naming Convention

All resources follow Azure Cloud Adoption Framework (CAF) naming standards:

### Standard Resources (with hyphens)
| Resource Type | Pattern | Example |
|--------------|---------|---------|
| Management Group | `mg-{org}-{workload}` | `mg-a10corp-sales` |
| Resource Group | `rg-{org}-{workload}-{env}` | `rg-a10corp-sales-dev` |
| Virtual Machine | `vm-{org}-{workload}-{env}` | `vm-a10corp-sales-dev` |

### No-Hyphen Resources (alphanumeric only)
| Resource Type | Pattern | Example |
|--------------|---------|---------|
| Storage Account | `st{org}{workload}{env}` | `sta10corpsalesdev` |

**Implementation**: [modules/common/naming.tf](modules/common/naming.tf) - Centralized three-branch naming logic

**Learn More**: [docs/DECISIONS.md - Decision 16](docs/DECISIONS.md#decision-16-three-branch-naming-system-for-azure-resource-restrictions)

---

## 📁 Project Structure

```
terraform_iac/                  # Repository root
├── foundation/                 # Foundation root caller (GLOBAL - no environments)
│   ├── backend.tf              # Azure Storage backend config
│   ├── main.tf                 # Calls common + foundation modules
│   └── environments/backend.hcl
├── workloads/                  # Workloads root caller (PER-ENVIRONMENT)
│   ├── backend.tf              # Azure Storage backend config
│   ├── main.tf                 # Calls common + workloads modules
│   ├── variables.tf            # Environment override
│   └── environments/
│       ├── dev.tfvars
│       ├── stage.tfvars
│       ├── prod.tfvars
│       ├── backend-dev.hcl
│       ├── backend-stage.hcl
│       └── backend-prod.hcl
├── modules/
│   ├── common/                 # Shared naming, variables, Key Vault (library)
│   │   ├── naming.tf
│   │   ├── variables.tf
│   │   ├── data-sources.tf
│   │   └── outputs.tf
│   ├── foundation/             # Management groups module
│   │   ├── main.tf
│   │   ├── subscriptions.tf
│   │   └── outputs.tf
│   └── workloads/              # Resource groups module
│       ├── main.tf
│       └── outputs.tf
├── docs/
│   ├── DECISIONS.md            # Architectural Decision Records
│   ├── TERRAFORM_COMMANDS.md   # Command reference
│   ├── azure.md                # Azure resource inventory
│   └── sessions/               # Session history
├── CLAUDE.md                   # AI assistant context
├── README.md                   # This file
├── .env.example                # Template for environment variables
└── .gitignore
```

---

## 🔒 Security & Secrets Management

### Key Vault Integration

**Native Terraform approach** - No external scripts required:

```hcl
# Terraform fetches secrets directly from Key Vault
data "azurerm_key_vault_secret" "hq_subscription_id" {
  name         = "terraform-${var.environment}-hq-sub-id"
  key_vault_id = data.azurerm_key_vault.terraform.id
}
```

**Benefits**:
- ✅ Simplified workflow (just `terraform plan`)
- ✅ Audit trail via Key Vault access logs
- ✅ RBAC enforcement via Azure AD
- ✅ Works seamlessly in CI/CD

### Secret Structure

```
kv-root-terraform/
# 9 secrets total (3 per environment)
├── terraform-dev-hq-sub-id       # HQ subscription ID (dev)
├── terraform-dev-sales-sub-id    # Sales subscription ID (dev)
├── terraform-dev-service-sub-id  # Service subscription ID (dev)
├── terraform-stage-* (same pattern)
└── terraform-prod-* (same pattern)
```

**Note**: Tenant ID and root subscription ID are derived from authenticated context (`az login` or GitHub Actions OIDC), not stored in Key Vault.

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: `Error: building account: subscription ID could not be determined`

**Solution**: Source `.env` file before running Terraform:
```bash
source .env
terraform plan -var-file="environments/dev.tfvars"
```

---

**Issue**: `Error: authorization failed for Key Vault`

**Solution**: Verify RBAC permissions:
```bash
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee $(az ad signed-in-user show --query mail -o tsv) \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-root-iac/providers/Microsoft.KeyVault/vaults/kv-root-terraform
```

---

**Issue**: Wrong environment deployed

**Solution**: Always use both backend config AND var-file together:
```bash
# Dev
terraform init -reconfigure -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars"

# Stage
terraform init -reconfigure -backend-config="environments/backend-stage.hcl"
terraform plan -var-file="environments/stage.tfvars"
```

**More Help**: See [docs/TERRAFORM_COMMANDS.md](docs/TERRAFORM_COMMANDS.md#troubleshooting)

---

## 🔄 CI/CD Pipeline

GitHub Actions workflow with OIDC authentication (zero long-lived secrets):

**Status**: Planned (see [docs/DECISIONS.md - Decision 9](docs/DECISIONS.md#decision-9-cicd-authentication-method))

**Required GitHub Secrets**:
- `AZURE_CLIENT_ID` - App Registration client ID
- `AZURE_TENANT_ID` - Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` - Root subscription ID

**Setup Guide**: [secure/OIDC_SETUP.md](secure/OIDC_SETUP.md)

---

## 🤝 Contributing

This is a private repository for A10 Corporation infrastructure.

**For Questions**:
1. Review [docs/DECISIONS.md](docs/DECISIONS.md) for architectural context
2. Check [CLAUDE.md](CLAUDE.md) for current status
3. Contact the infrastructure team

---

## 📝 License

Private - All Rights Reserved

---

## 🔗 Quick Links

- **Azure CAF**: https://learn.microsoft.com/azure/cloud-adoption-framework/
- **Terraform azurerm Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure Management Groups**: https://learn.microsoft.com/azure/governance/management-groups/
- **GitHub OIDC**: https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure

---

**Last Updated**: 2025-12-17
**Terraform Version**: >= 1.0
**Azure Provider Version**: ~> 4.0
**Repository**: [github.com:amaramdotme/A10_Corp-terraform.git](https://github.com/amaramdotme/A10_Corp-terraform.git) (private)
