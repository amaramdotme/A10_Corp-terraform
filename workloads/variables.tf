# ============================================================
# Workloads Root Variables
# ============================================================
# MINIMAL variables - just environment.
# All other values use defaults from common module.

variable "environment" {
  description = "Environment name (dev, stage, prod) - set via .tfvars file"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod"
  }
}
