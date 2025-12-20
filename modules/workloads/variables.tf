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



variable "vnet_address_space" {

  description = "Address space for the Workload VNet"

  type        = list(string)

}



variable "subnet_aks_prefix" {

  description = "Address prefixes for the AKS nodes subnet"

  type        = list(string)

}



variable "subnet_ingress_prefix" {

  description = "Address prefixes for the Ingress subnet"

  type        = list(string)

}



variable "acr_id" {

  description = "Resource ID of the global ACR for AcrPull assignment"

  type        = string

}