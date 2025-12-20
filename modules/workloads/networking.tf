# ============================================================
# Workloads Module - Networking
# VNet and Subnets for the Sales Workload
# ============================================================

resource "azurerm_virtual_network" "sales" {
  provider = azurerm.sales

  name                = var.naming_patterns["azurerm_virtual_network"]["sales"]
  resource_group_name = azurerm_resource_group.sales.name
  location            = azurerm_resource_group.sales.location
  address_space       = var.vnet_address_space

  tags = merge(
    var.common_tags,
    {
      Workload = "Sales"
      Layer    = "Networking"
    }
  )
}

# Subnet: AKS Nodes
# Result: snet-a10corp-sales-dev-aks-nodes
resource "azurerm_subnet" "aks_nodes" {
  provider = azurerm.sales

  name                 = "${var.naming_patterns["azurerm_subnet"]["sales"]}-aks-nodes"
  resource_group_name  = azurerm_resource_group.sales.name
  virtual_network_name = azurerm_virtual_network.sales.name
  address_prefixes     = var.subnet_aks_prefix
}

# Subnet: Ingress
# Result: snet-a10corp-sales-dev-ingress
resource "azurerm_subnet" "ingress" {
  provider = azurerm.sales

  name                 = "${var.naming_patterns["azurerm_subnet"]["sales"]}-ingress"
  resource_group_name  = azurerm_resource_group.sales.name
  virtual_network_name = azurerm_virtual_network.sales.name
  address_prefixes     = var.subnet_ingress_prefix
}
