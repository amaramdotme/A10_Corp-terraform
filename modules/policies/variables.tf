variable "management_group_id" {
  description = "The ID of the Management Group to assign policies to"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions for resources"
  type        = list(string)
  default     = ["eastus", "eastus2"]
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