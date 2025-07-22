# networking.tf
# Define la topología de red: Grupos de Recursos, VNets, Subredes, NSGs y Peering.

# --- Grupos de Recursos ---
resource "azurerm_resource_group" "hub_rg" {
  name     = "${var.resource_group_name_prefix}-hub-${var.env}"
  location = var.location
}

resource "azurerm_resource_group" "spoke_rg" {
  name     = "${var.resource_group_name_prefix}-spoke-${var.env}"
  location = var.location
}

# --- Redes Virtuales ---
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub-${var.env}"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  address_space       = var.hub_vnet_address_space
}

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "vnet-spoke-${var.env}"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  location            = azurerm_resource_group.spoke_rg.location
  address_space       = var.spoke_vnet_address_space
}

# --- Subredes en el Spoke ---
resource "azurerm_subnet" "appgw_snet" {
  name                 = "snet-appgw-${var.env}-01"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["172.16.132.0/26"]
}

resource "azurerm_subnet" "apim_snet" {
  name                 = "snet-apim-${var.env}-01"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["172.16.132.64/27"]
}

resource "azurerm_subnet" "privatelink_snet" {
  name                 = "snet-privatelink-${var.env}-01"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["172.16.132.96/27"]
  private_endpoint_network_policies_enabled = true
}

# --- Grupos de Seguridad de Red (NSG) y Asociaciones ---
resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "nsg-appgw-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet_network_security_group_association" "appgw_nsg_assoc" {
  subnet_id                 = azurerm_subnet.appgw_snet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

resource "azurerm_network_security_group" "apim_nsg" {
  name                = "nsg-apim-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet_network_security_group_association" "apim_nsg_assoc" {
  subnet_id                 = azurerm_subnet.apim_snet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}

# --- Reglas NSG para Application Gateway (Requeridas por Azure) ---
resource "azurerm_network_security_rule" "appgw_allow_health_probes" {
  name                        = "Allow-Health-Probes"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "appgw_allow_gateway_mgmt" {
  name                        = "Allow-Gateway-Mgmt"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "appgw_allow_client_https" {
  name                        = "Allow-Client-HTTPS"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "appgw_allow_client_http" {
  name                        = "Allow-Client-HTTP"
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# --- Reglas NSG para API Management (Requeridas por Azure y para seguridad) ---
resource "azurerm_network_security_rule" "apim_allow_mgmt" {
  name                        = "Allow-APIM-Mgmt"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_allow_lb_probes" {
  name                        = "Allow-LB-Probes"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6390"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_allow_from_appgw" {
  name                        = "Allow-From-AppGateway"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = azurerm_subnet.appgw_snet.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_deny_all_internet" {
  name                        = "Deny-All-Internet"
  priority                    = 4095
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_allow_out_storage" {
  name                        = "Allow-Out-Storage"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Storage"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_allow_out_keyvault" {
  name                        = "Allow-Out-KeyVault"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureKeyVault"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "apim_allow_out_monitor" {
  name                        = "Allow-Out-AzureMonitor"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "1886"]
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureMonitor"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# --- Peering de VNet ---
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.spoke_rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_gateway_transit        = false # Cambiar a true si el Hub tiene un VPN/ER Gateway
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke-${var.env}"
  resource_group_name          = azurerm_resource_group.hub_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false # Cambiar a true si el Hub tiene un VPN/ER Gateway
}
