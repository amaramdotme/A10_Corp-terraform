# ============================================================
# Workloads Module Input Variables
# Type declarations only - no defaults (values passed from parent)
# ============================================================

variable "naming_patterns" {
  description = "Map of resource types to workload-specific names from common module"
  type        = map(map(string))
}

variable "location" {
  description = "Azure region (from common module)"
  type        = string
}

variable "common_tags" {
  description = "Common tags (from common module)"
  type        = map(string)
}
