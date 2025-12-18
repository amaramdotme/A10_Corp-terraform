# ============================================================
# Foundation Root Module - Input Variables
# ============================================================

variable "org_name" {
  description = "Organization name used in resource naming (e.g., 'a10corp')"
  type        = string
  default     = "a10corp"
}

variable "location" {
  description = "Azure region for resources (e.g., 'eastus')"
  type        = string
  default     = "eastus"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Global"
    ManagedBy   = "Terraform"
    Module      = "Foundation"
  }
}
