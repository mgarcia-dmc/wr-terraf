
# api_platform.tf
# Defines the core platform components: APIM and Application Gateway.

# --- Public IP for Application Gateway ---
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-${var.env}"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  location            = azurerm_resource_group.spoke_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # For high availability
}

# --- API Management ---
resource "azurerm_api_management" "apim" {
  name                = "apim-corp-${var.env}"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  
  # CORRECTED: SKU changed to "Developer_1" to support VNet integration.
  sku_name            = "Developer_1"

  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_snet.id
  }

  # CORRECTED: Using a User-Assigned Identity to prevent race conditions.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apim_identity.id]
  }

  depends_on = [
    azurerm_key_vault_access_policy.apim_policy
  ]
}

# --- Application Gateway ---
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-corp-${var.env}"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  location            = azurerm_resource_group.spoke_rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_version         = "3.2"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_identity.id]
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_snet.id
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name  = "apim-backend-pool"
    fqdns = ["${azurerm_api_management.apim.name}.azure-api.net"]
  }

  backend_http_settings {
    name                  = "apim-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    probe_name            = "apim-health-probe"
    host_name             = "${azurerm_api_management.apim.name}.azure-api.net"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    ssl_certificate_name           = "kv-cert-integration"
    host_name                      = "api.yourcompany.com" # Replace with your custom domain
  }

  request_routing_rule {
    name                       = "api-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "apim-backend-pool"
    backend_http_settings_name = "apim-http-settings"
  }

  ssl_certificate {
    name                = "kv-cert-integration"
    # NOTE: You must create a certificate in Key Vault and reference its secret ID.
    key_vault_secret_id = "${azurerm_key_vault.main.vault_uri}secrets/placeholder-cert-name"
  }

  probe {
    name                = "apim-health-probe"
    protocol            = "Https"
    path                = "/status-0123456789abcdef"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "${azurerm_api_management.apim.name}.azure-api.net"
    pick_host_name_from_backend_http_settings = false
    match {
      status_code = ["200"]
    }
  }
  
  depends_on = [
    azurerm_key_vault_access_policy.appgw_policy,
    azurerm_api_management.apim
  ]
}
