# A10 Corp Azure Infrastructure - Terraform IaC

Enterprise-grade Terraform Infrastructure as Code for managing Azure Management Groups, Subscriptions, and Resource Groups with native Key Vault integration and multi-environment support.

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue?logo=microsoftazure)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-Private-red)]()

## 🏗️ Architecture Overview

This repository implements Azure Cloud Adoption Framework (CAF) compliant infrastructure with the following hierarchy:

```
Tenant Root Group
├── sub-root (Infrastructure subscription - stays in root)
└── mg-a10corp-hq (Root management group)
    ├── sub-hq → rg-a10corp-shared-{env}
    ├── mg-a10corp-sales
    │   └── sub-sales → rg-a10corp-sales-{env}
    └── mg-a10corp-service
        └── sub-service → rg-a10corp-service-{env}
```

### Key Components

- **3 Management Groups**: Hierarchical organization structure
- **3 Subscription Associations**: Automated subscription placement
- **3 Resource Groups per Environment**: Isolated workload containers
- **Multi-Environment Support**: Dev, Stage, and Production configurations
- **Native Key Vault Integration**: Secure credential management without external scripts

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.0 ([Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **Azure CLI** ([Installation Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Azure Permissions**:
  - Management Group Contributor (tenant level)
  - Key Vault Secrets Officer (on `kv-root-terraform`)
  - Contributor (on target subscriptions)

### Initial Setup

```bash
# 1. Clone the repository
git clone git@github.com:GoldenSapien/A10_Corp-terraform.git
cd A10_Corp-terraform

# 2. Authenticate to Azure
az login

# 3. Create .env file from template
cp .env.example .env

# 4. Edit .env with your Azure credentials
# Get values from: az account show
nano .env  # Update ARM_SUBSCRIPTION_ID and ARM_TENANT_ID

# 5. Load environment variables
source .env

# 6. Initialize Terraform
terraform init

# 7. Validate configuration
terraform validate

# 8. Plan infrastructure changes
terraform plan -var-file="environments/dev.tfvars"
```

## 📋 Usage

### Development Workflow

```bash
# Load environment variables (required for each terminal session)
source .env

# Plan changes and save to file (RECOMMENDED)
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# Review the plan output carefully

# Apply the saved plan (no confirmation prompt)
terraform apply dev.tfplan

# Verify created resources
terraform state list
```

**Why use `-out`?**
- ✅ Guarantees the exact plan you reviewed gets applied
- ✅ Prevents infrastructure drift between plan and apply
- ✅ No manual confirmation needed (plan already approved)
- ✅ Required for production deployments

### Multi-Environment Deployment

**Best Practice:** Always use `-out` to save plans before applying.

```bash
# Development
source .env
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan

# Staging
source .env
terraform plan -var-file="environments/stage.tfvars" -out=stage.tfplan
terraform apply stage.tfplan

# Production (extra review recommended!)
source .env
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
# Review plan output carefully before applying to production
terraform apply prod.tfplan
```

### Common Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize providers and modules |
| `terraform validate` | Check configuration syntax |
| `terraform fmt -recursive` | Format code to canonical style |
| `terraform plan -var-file="environments/dev.tfvars"` | Preview infrastructure changes |
| `terraform apply dev.tfplan` | Apply planned changes |
| `terraform state list` | List all managed resources |
| `terraform destroy -var-file="environments/dev.tfvars"` | Destroy all resources (use with caution) |

## 🔒 Security & Secrets Management

### Key Vault Integration

This project uses **native Terraform Key Vault integration** for secure credential management:

- **No external scripts needed** - Terraform fetches secrets directly
- **9 secrets total** - 3 subscription IDs × 3 environments
- **Audit trail** - All secret access logged in Azure Key Vault
- **RBAC enforced** - Access controlled via Azure AD roles

### Secret Structure

```
kv-root-terraform/
├── terraform-dev-hq-sub-id       # HQ subscription ID (dev)
├── terraform-dev-sales-sub-id    # Sales subscription ID (dev)
├── terraform-dev-service-sub-id  # Service subscription ID (dev)
├── terraform-stage-hq-sub-id     # (stage environment)
├── terraform-stage-sales-sub-id
├── terraform-stage-service-sub-id
├── terraform-prod-hq-sub-id      # (production environment)
├── terraform-prod-sales-sub-id
└── terraform-prod-service-sub-id
```

### Environment Variables (.env file)

Authentication context (tenant ID and root subscription) is provided via environment variables:

```bash
# .env (gitignored)
export ARM_SUBSCRIPTION_ID="fdb297a9-2ece-469c-808d-a8227259f6e8"  # sub-root
export ARM_TENANT_ID="8116fad0-5032-463e-b911-cc6d1d75001d"
```

**Why this approach?**
- Tenant ID and root subscription are derived from authenticated context (standard Terraform pattern)
- Only subscription IDs used in resources are stored in Key Vault
- Reduces Key Vault secrets from 12 to 9 (25% reduction)

## 📁 Project Structure

```
.
├── README.md                    # This file
├── CLAUDE.md                    # AI assistant context and session notes
├── DECISIONS.md                 # Architectural decision records (ADRs)
├── TERRAFORM_COMMANDS.md        # Comprehensive Terraform command reference
├── azure.md                     # Azure architecture documentation
├── providers.tf                 # Provider configuration (azurerm)
├── variables.tf                 # Variable declarations
├── data-sources.tf              # Key Vault and client config data sources
├── naming.tf                    # Centralized CAF naming logic
├── management-groups.tf         # Management group hierarchy
├── subscriptions.tf             # Subscription associations
├── resource-groups.tf           # Resource group definitions
├── outputs.tf                   # Output values
├── imports.tf                   # Import blocks for existing resources
├── .env                         # Environment variables (gitignored)
├── .env.example                 # Template for environment variables
├── environments/                # Environment-specific configurations
│   ├── dev.tfvars              # Development environment
│   ├── stage.tfvars            # Staging environment
│   └── prod.tfvars             # Production environment
├── secure/                      # Sensitive documentation (gitignored)
│   └── OIDC_SETUP.md           # GitHub Actions OIDC configuration
└── .github/
    └── workflows/
        └── terraform-deploy.yml # CI/CD pipeline (GitHub Actions)
```

## 🎯 Features

### ✅ Implemented

- ✅ **Azure CAF Naming Convention** - Pure Terraform locals (no external providers)
- ✅ **Multi-Environment Support** - Dev, Stage, Production via `.tfvars` files
- ✅ **Native Key Vault Integration** - Direct Terraform data sources (no scripts)
- ✅ **Hierarchical Management Groups** - 3-tier structure with subscription associations
- ✅ **Environment-Specific Resource Groups** - Isolated workload containers
- ✅ **OIDC Authentication** - GitHub Actions with no long-lived secrets
- ✅ **Circular Dependency Resolution** - Smart provider configuration with env vars
- ✅ **Optimized Secret Storage** - Only 9 Key Vault secrets (tenant ID from context)

### 🔄 Planned (See DECISIONS.md Decision 11)

- 🔄 **Two-Module Architecture** - Separate foundation (MGs) and workloads (RGs)
- 🔄 **Remote State Backend** - Azure Storage with separate containers per module
- 🔄 **State Locking** - Prevent concurrent modifications
- 🔄 **Module Separation** - Independent lifecycle management

## 🏷️ Naming Convention

All resources follow Azure Cloud Adoption Framework (CAF) naming patterns:

| Resource Type | Pattern | Example |
|--------------|---------|---------|
| Management Group | `mg-{org}-{workload}` | `mg-a10corp-sales` |
| Resource Group | `rg-{org}-{workload}-{env}` | `rg-a10corp-sales-dev` |
| Virtual Machine | `vm-{org}-{workload}-{env}` | `vm-a10corp-sales-dev` |
| Storage Account | `st{org}{workload}{env}` | `sta10corpsalesdev` |

**Implementation**: All naming logic is centralized in [naming.tf](naming.tf) using pure Terraform locals.

## 🔧 Configuration

### Environment Variables (.env)

Create from template and customize:

```bash
cp .env.example .env
```

Required variables:
- `ARM_SUBSCRIPTION_ID` - Root subscription ID (where Key Vault lives)
- `ARM_TENANT_ID` - Azure AD tenant ID

Get values from:
```bash
az account show
```

### Environment-Specific Variables (environments/*.tfvars)

Minimal configuration required:

```hcl
# environments/dev.tfvars
environment = "dev"

# Other variables use defaults from variables.tf:
# - org_name = "a10corp"
# - location = "eastus"
# - common_tags = { ManagedBy = "Terraform", ... }
```

### Subscription IDs (Azure Key Vault)

Stored as individual secrets in `kv-root-terraform`:

```bash
# Create secrets (one-time setup)
az keyvault secret set \
  --vault-name kv-root-terraform \
  --name terraform-dev-hq-sub-id \
  --value "da1ba383-2bf5-4ee9-8b5f-fc6effb0a100"

# Repeat for: sales-sub-id, service-sub-id (and stage, prod variants)
```

## 🔄 CI/CD Pipeline

GitHub Actions workflow with OIDC authentication (no long-lived secrets):

```yaml
# Trigger: Manual workflow dispatch
# Environments: dev, stage, prod
# Authentication: Azure AD OIDC (zero secrets)
```

**Required GitHub Secrets:**
- `AZURE_CLIENT_ID` - App Registration client ID
- `AZURE_TENANT_ID` - Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` - Root subscription ID

See [secure/OIDC_SETUP.md](secure/OIDC_SETUP.md) for detailed setup instructions.

## 📚 Documentation

### Core Documents

- **[CLAUDE.md](CLAUDE.md)** - AI assistant context, session notes, and handoff instructions
- **[DECISIONS.md](DECISIONS.md)** - Architectural Decision Records (ADRs) with rationale
- **[TERRAFORM_COMMANDS.md](TERRAFORM_COMMANDS.md)** - Comprehensive command reference
- **[azure.md](azure.md)** - Azure architecture and resource hierarchy

### Key Decisions (Decision 14)

**Native Terraform Key Vault Integration** - Eliminates external scripts while maintaining security:

- ✅ Simplified workflow (one command vs two)
- ✅ Better CI/CD integration
- ✅ Audit trail via Key Vault logs
- ✅ Optimized to 9 secrets (tenant ID from authenticated context)

See [DECISIONS.md](DECISIONS.md#decision-14-secret-injection-method---native-terraform-vs-external-scripts) for complete analysis.

## 🐛 Troubleshooting

### Common Issues

**Issue**: `Error: building account: subscription ID could not be determined`

**Solution**: Ensure `.env` file is sourced before running Terraform:
```bash
source .env
terraform plan -var-file="environments/dev.tfvars"
```

---

**Issue**: `Error: authorization failed for Key Vault`

**Solution**: Verify RBAC permissions:
```bash
# Check current user
az ad signed-in-user show

# Grant Key Vault Secrets Officer role
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee <your-email> \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-root-iac/providers/Microsoft.KeyVault/vaults/kv-root-terraform
```

---

**Issue**: `Error: Cycle detected in provider configuration`

**Solution**: This is a known circular dependency. Ensure your `providers.tf` does NOT set `subscription_id` or `tenant_id` in the default provider block. They should come from environment variables only.

---

**Issue**: Variables not found during plan

**Solution**: Always specify the `-var-file` parameter:
```bash
terraform plan -var-file="environments/dev.tfvars"
```

## 🤝 Contributing

This is a private repository for A10 Corporation infrastructure. For questions or issues:

1. Review [DECISIONS.md](DECISIONS.md) for architectural context
2. Check [CLAUDE.md](CLAUDE.md) for session notes and status
3. Contact the infrastructure team

## 📝 License

Private - All Rights Reserved

---

## 🔗 Links

- **Azure Cloud Adoption Framework**: https://learn.microsoft.com/azure/cloud-adoption-framework/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure Management Groups**: https://learn.microsoft.com/azure/governance/management-groups/
- **GitHub OIDC Setup**: https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure

---

**Last Updated**: 2025-12-17
**Terraform Version**: >= 1.0
**Azure Provider Version**: ~> 4.0
