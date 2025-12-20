variable "management_group_id" {
  description = "The ID of the Management Group to assign policies to"
  type        = string
}

variable "location" {
  description = "The allowed Azure region for resources (e.g., eastus)"
  type        = string
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs to control costs"
  type        = list(string)
  default     = [
    "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
    "Standard_D2s_v3", "Standard_D4s_v3",
    "Standard_D2s_v4", "Standard_D4s_v4"
  ]
}