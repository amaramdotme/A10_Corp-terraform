variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "naming_patterns" {
  description = "Map of naming patterns from common module"
  type        = any
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics Workspace for diagnostics"
  type        = string
}