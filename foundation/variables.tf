# ============================================================
# Foundation Root Variables
# ============================================================
# See modules/common/variables.tf for full descriptions

variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "a10corp"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["eastus", "eastus2"]
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    ManagedBy  = "Terraform"
    Owner      = "A10Corp"
    CostCenter = "Engineering"
  }
}

variable "root_resource_group_name" {
  description = "Name of the permanent infrastructure resource group"
  type        = string
}

variable "root_key_vault_name" {
  description = "Name of the permanent infrastructure Key Vault"
  type        = string
}

variable "root_storage_account_name" {
  description = "Name of the permanent infrastructure Storage Account"
  type        = string
}
