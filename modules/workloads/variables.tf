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

variable "vnet_address_space" {
  description = "Address space for the Sales VNet"
  type        = list(string)
}

variable "subnet_aks_prefix" {
  description = "Address prefix for the AKS Nodes subnet"
  type        = list(string)
}

variable "subnet_ingress_prefix" {
  description = "Address prefix for the Ingress subnet"
  type        = list(string)
}

variable "acr_id" {
  description = "Resource ID of the global ACR for AcrPull assignment"
  type        = string
}
