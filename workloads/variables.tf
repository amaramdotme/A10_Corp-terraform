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
