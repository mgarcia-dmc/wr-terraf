# security.tf
# Gestiona recursos de seguridad: Log Analytics, Key Vault, Private Endpoints y DNS Privado.

# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-apim-platform-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- Identidades Administradas ---
resource "azurerm_user_assigned_identity" "appgw_identity" {
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  name                = "id-appgw-${var.env}"
}

# --- Key Vault ---
resource "azurerm_key_vault" "main" {
  name                        = "kv-apim-corp-${var.env}"
  location                    = azurerm_resource_group.spoke_rg.location
  resource_group_name         = azurerm_resource_group.spoke_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  public_network_access_enabled = false # Deshabilita el acceso público
}

# --- Políticas de Acceso a Key Vault ---
resource "azurerm_key_vault_access_policy" "appgw_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw_identity.principal_id

  certificate_permissions = ["Get"]
  secret_permissions    = ["Get"]
}

resource "azurerm_key_vault_access_policy" "apim_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_api_management.apim.identity.principal_id

  certificate_permissions = ["Get"]
  secret_permissions    = ["Get"]
}

# --- Private Endpoint para Key Vault ---
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
}

# --- DNS Privado para resolver el Private Endpoint ---
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

# --- Grupo de Zonas DNS para el Private Endpoint ---
resource "azurerm_private_endpoint_application_security_group_association" "kv_pe_asg_assoc" {
  private_endpoint_id          = azurerm_private_endpoint.kv_pe.id
  application_security_group_id = azurerm_application_security_group.kv_asg.id
}

resource "azurerm_application_security_group" "kv_asg" {
  name                = "asg-kv-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_private_dns_zone_group" "kv_pdzg" {
  name                 = "pdzg-kv-${var.env}"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  private_endpoint_name = azurerm_private_endpoint.kv_pe.name
  private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
}
