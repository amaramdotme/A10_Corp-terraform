# ============================================================
# Foundation Module - Variable Declarations
# ============================================================

variable "naming_patterns" {
  description = "Naming patterns from common module for all resource types"
  type        = map(map(string))
}

variable "tenant_id" {
  description = "Azure Tenant ID (fetched from Key Vault via common module)"
  type        = string
  sensitive   = true
}

variable "hq_subscription_id" {
  description = "HQ subscription ID (fetched from Key Vault via common module)"
  type        = string
  sensitive   = true
}

variable "sales_subscription_id" {
  description = "Sales subscription ID (fetched from Key Vault via common module)"
  type        = string
  sensitive   = true
}

variable "service_subscription_id" {
  description = "Service subscription ID (fetched from Key Vault via common module)"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
