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

# ============================================================
# Observability
# ============================================================

resource "azurerm_monitor_diagnostic_setting" "vnet_sales" {
  provider = azurerm.sales

  name                       = "diag-${azurerm_virtual_network.sales.name}"
  target_resource_id         = azurerm_virtual_network.sales.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ============================================================
# Network Security Groups (NSGs)
# ============================================================

# NSG: AKS Nodes
# Result: nsg-a10corp-sales-dev-aks-nodes
resource "azurerm_network_security_group" "aks_nodes" {
  provider = azurerm.sales

  name                = "${var.naming_patterns["azurerm_network_security_group"]["sales"]}-aks-nodes"
  location            = azurerm_resource_group.sales.location
  resource_group_name = azurerm_resource_group.sales.name

  tags = merge(
    var.common_tags,
    {
      Layer = "Security"
    }
  )
}

resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  provider = azurerm.sales

  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}

# NSG: Ingress
# Result: nsg-a10corp-sales-dev-ingress
# trivy:ignore:AVD-AZU-0047 # Intentionally allowing public ingress for Web Application Gateway
resource "azurerm_network_security_group" "ingress" {
  provider = azurerm.sales

  name                = "${var.naming_patterns["azurerm_network_security_group"]["sales"]}-ingress"
  location            = azurerm_resource_group.sales.location
  resource_group_name = azurerm_resource_group.sales.name

  # Allow HTTP Inbound (Placeholder rule - explicitly allowing Web traffic)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS Inbound
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(
    var.common_tags,
    {
      Layer = "Security"
    }
  )
}

resource "azurerm_subnet_network_security_group_association" "ingress" {
  provider = azurerm.sales

  subnet_id                 = azurerm_subnet.ingress.id
  network_security_group_id = azurerm_network_security_group.ingress.id
}

# ============================================================
# Route Tables (UDRs)
# ============================================================

# Route Table: Sales (Shared)
# Result: route-a10corp-sales-dev
resource "azurerm_route_table" "sales" {
  provider = azurerm.sales

  name                = var.naming_patterns["azurerm_route_table"]["sales"]
  location            = azurerm_resource_group.sales.location
  resource_group_name = azurerm_resource_group.sales.name

  # Default Route (0.0.0.0/0) -> Internet
  # Explicitly defining this allows us to change it later (e.g., to a Firewall IP)
  route {
    name           = "DefaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = merge(
    var.common_tags,
    {
      Layer = "Networking"
    }
  )
}

resource "azurerm_subnet_route_table_association" "aks_nodes" {
  provider = azurerm.sales

  subnet_id      = azurerm_subnet.aks_nodes.id
  route_table_id = azurerm_route_table.sales.id
}

resource "azurerm_subnet_route_table_association" "ingress" {
  provider = azurerm.sales

  subnet_id      = azurerm_subnet.ingress.id
  route_table_id = azurerm_route_table.sales.id
}

# ============================================================
# NSG Observability (Diagnostics)
# ============================================================

resource "azurerm_monitor_diagnostic_setting" "nsg_aks_nodes" {
  provider = azurerm.sales

  name                       = "diag-${azurerm_network_security_group.aks_nodes.name}"
  target_resource_id         = azurerm_network_security_group.aks_nodes.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_ingress" {
  provider = azurerm.sales

  name                       = "diag-${azurerm_network_security_group.ingress.name}"
  target_resource_id         = azurerm_network_security_group.ingress.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
