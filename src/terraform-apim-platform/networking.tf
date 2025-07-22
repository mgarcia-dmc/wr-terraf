
# networking.tf
# Defines the network topology: Resource Groups, VNets, Subnets, NSGs, and Peering.

# --- Resource Groups ---
resource "azurerm_resource_group" "hub_rg" {
  name     = "${var.resource_group_name_prefix}-hub-${var.env}"
  location = var.location
}

resource "azurerm_resource_group" "spoke_rg" {
  name     = "${var.resource_group_name_prefix}-spoke-${var.env}"
  location = var.location
}

# --- Virtual Networks ---
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

# --- Subnets in the Spoke ---
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

# --- Network Security Groups (NSG) and Associations ---
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

# --- NSG Rules for Application Gateway (Required by Azure) ---
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

# --- NSG Rules for API Management (Required by Azure and for security) ---
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

resource "azurerm_network_security_rule" "apim_allow_from_appgw" {
  name                        = "Allow-From-AppGateway"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefixes     = azurerm_subnet.appgw_snet.address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# --- VNet Peering ---
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.spoke_rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke-${var.env}"
  resource_group_name          = azurerm_resource_group.hub_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
