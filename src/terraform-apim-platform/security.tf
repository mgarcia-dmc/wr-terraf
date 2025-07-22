
# security.tf
# Manages security resources: Key Vault, Identities, Private Endpoints, and DNS.

# --- Managed Identities ---
resource "azurerm_user_assigned_identity" "appgw_identity" {
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  name                = "id-appgw-${var.env}"
}

resource "azurerm_user_assigned_identity" "apim_identity" {
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  name                = "id-apim-${var.env}"
}

# --- Key Vault ---
resource "azurerm_key_vault" "main" {
  name                        = "kv-apim-corp-${var.env}"
  location                    = azurerm_resource_group.spoke_rg.location
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  public_network_access_enabled = false # Disables public access
}

# --- Key Vault Access Policies ---
resource "azurerm_key_vault_access_policy" "appgw_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw_identity.principal_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "apim_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.apim_identity.principal_id
  secret_permissions = ["Get", "List"]
}

# --- Private DNS for Key Vault ---
resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_vnet_link" {
  name                  = "link-spoke-vnet-to-kv-zone-${var.env}"
  resource_group_name   = azurerm_resource_group.spoke_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
}

# --- Private Endpoint for Key Vault ---
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-kv-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  subnet_id           = azurerm_subnet.privatelink_snet.id

  private_service_connection {
    name                           = "psc-kv-${var.env}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
  }
}
