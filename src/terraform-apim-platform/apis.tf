# apis.tf
# Define las APIs de ejemplo, productos y políticas dentro de APIM.

# --- Producto para agrupar las APIs ---
resource "azurerm_api_management_product" "main" {
  product_id            = "corp-apis"
  display_name          = "APIs Corporativas"
  subscription_required = true
  approval_required     = false
  published             = true
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.spoke_rg.name
}

# --- API de Ejemplo 1: Estudiantes ---
resource "azurerm_api_management_api" "students_api" {
  name                = "students-api"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "API de Estudiantes"
  path                = "students"
  protocols           = ["https"]
  service_url         = "http://api.example.com/students" # URL del backend real
}

resource "azurerm_api_management_product_api" "students_api_link" {
  api_name              = azurerm_api_management_api.students_api.name
  product_id            = azurerm_api_management_product.main.product_id
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.spoke_rg.name
}

# --- API de Ejemplo 2: SUNEDU ---
resource "azurerm_api_management_api" "sunedu_api" {
  name                = "sunedu-api"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "API de SUNEDU"
  path                = "sunedu"
  protocols           = ["https"]
  service_url         = "http://api.example.com/sunedu"
}

resource "azurerm_api_management_product_api" "sunedu_api_link" {
  api_name              = azurerm_api_management_api.sunedu_api.name
  product_id            = azurerm_api_management_product.main.product_id
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.spoke_rg.name
}

# --- API de Ejemplo 3: Servicios Internos (con validación JWT) ---
resource "azurerm_api_management_api" "internal_api" {
  name                = "internal-services-api"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "API de Servicios Internos"
  path                = "internal"
  protocols           = ["httpss"]
  service_url         = "http://api.example.com/internal"
}

resource "azurerm_api_management_product_api" "internal_api_link" {
  api_name              = azurerm_api_management_api.internal_api.name
  product_id            = azurerm_api_management_product.main.product_id
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.spoke_rg.name
}

# --- Política de Validación JWT para la API Interna ---
# NOTA: Reemplaza {YOUR_TENANT_ID} y {YOUR_CLIENT_ID} con los valores de tu Azure AD.
resource "azurerm_api_management_api_policy" "internal_api_jwt_policy" {
  api_name            = azurerm_api_management_api.internal_api.name
  resource_group_name = azurerm_resource_group.spoke_rg.name
  api_management_name = azurerm_api_management.apim.name

  xml_content = <<XML
  <policies>
      <inbound>
          <base />
          <validate-jwt header-name="Authorization" failed-validation-httpcode="401" require-scheme="Bearer">
              <openid-config url="https://login.microsoftonline.com/{YOUR_TENANT_ID}/v2.0/.well-known/openid-configuration" />
              <audiences>
                  <audience>api://{YOUR_CLIENT_ID}</audience>
              </audiences>
              <issuers>
                  <issuer>https://sts.windows.net/{YOUR_TENANT_ID}/</issuer>
              </issuers>
          </validate-jwt>
      </inbound>
      <backend>
          <base />
      </backend>
      <outbound>
          <base />
      </outbound>
      <on-error>
          <base />
      </on-error>
  </policies>
  XML
}
