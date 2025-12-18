# ============================================================
# Foundation Backend Configuration
# Stores Terraform state in Azure Storage
# ============================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-root-iac"
    storage_account_name = "storerootblob"
    container_name       = "foundation"
    # key is set via backend config file:
    # terraform init -backend-config="environments/backend.hcl"
  }
}

# Note: Foundation has a single state file (no environment variants)
# Container name is just "foundation" (not "foundation-dev/stage/prod")
