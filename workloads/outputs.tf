# ============================================================
# Workloads Root Outputs
# ============================================================

output "resource_groups" {
  description = "Resource Group names and IDs"
  value       = module.workloads.resource_groups
}

# ============================================================
# Networking Outputs
# ============================================================

output "vnet_id" {
  description = "ID of the Sales VNet"
  value       = module.workloads.vnet_id
}

output "subnet_id_aks_nodes" {
  description = "ID of the AKS Nodes subnet"
  value       = module.workloads.subnet_id_aks_nodes
}

output "subnet_id_ingress" {
  description = "ID of the Ingress subnet"
  value       = module.workloads.subnet_id_ingress
}

# ============================================================
# Identity Outputs
# ============================================================

output "identity_id_aks" {
  description = "Resource ID of the AKS User Assigned Identity"
  value       = module.workloads.identity_id_aks
}

output "identity_client_id_aks" {
  description = "Client ID of the AKS User Assigned Identity"
  value       = module.workloads.identity_client_id_aks
}