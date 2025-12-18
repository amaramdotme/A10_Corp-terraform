# ============================================================
# Workloads Remote State Backend
# ============================================================
# Environment-specific state files in Azure Storage
#
# State file locations:
#   - workloads-dev/terraform.tfstate
#   - workloads-stage/terraform.tfstate
#   - workloads-prod/terraform.tfstate
#
# Backend configuration is partially defined here and completed
# via backend config file or CLI flags:
#
#   terraform init -backend-config="key=workloads-${environment}.tfstate"
#
# Or use a backend config file (recommended for CI/CD):
#   terraform init -backend-config=backend-dev.hcl

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-root-iac"
    storage_account_name = "storerootblob"
    container_name       = "workloads"
    # key is set via CLI or backend config file
    # Example: key = "workloads-dev.tfstate"
  }
}
