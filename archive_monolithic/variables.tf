# Subscription and Tenant IDs are now fetched from Azure Key Vault
# See data-sources.tf and DECISIONS.md Decision 14

# Environment (only variable that differs across environments)
variable "environment" {
  description = "Environment name for naming convention (dev, stage, prod)"
  type        = string
}

# Location Variables (same across all environments)
variable "location" {
  description = "The Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

# Naming Convention Variables (same across all environments)
variable "org_name" {
  description = "Organization name for naming convention"
  type        = string
  default     = "a10corp"
}

# Tags (same across all environments - environment-specific tag is dynamic)
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy  = "Terraform"
    Owner      = "A10Corp"
    CostCenter = "Engineering"
  }
}
