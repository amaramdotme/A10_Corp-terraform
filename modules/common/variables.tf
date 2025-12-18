# ============================================================
# Common Module Variables
# Shared variables used by both foundation and workloads modules
# ============================================================

variable "environment" {
  description = "Environment name for naming convention (dev, stage, prod). Optional - omit for foundation resources."
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be empty (for foundation) or one of: dev, stage, prod"
  }
}

variable "location" {
  description = "The Azure region for resource deployment"
  type        = string
  default     = "eastus"

  validation {
    condition     = can(regex("^[a-z]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces)"
  }
}

variable "org_name" {
  description = "Organization name for naming convention"
  type        = string
  default     = "a10corp"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.org_name))
    error_message = "Organization name must be lowercase alphanumeric only"
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy  = "Terraform"
    Owner      = "A10Corp"
    CostCenter = "Engineering"
  }

  validation {
    condition     = can(var.common_tags["ManagedBy"])
    error_message = "common_tags must include 'ManagedBy' key"
  }
}
