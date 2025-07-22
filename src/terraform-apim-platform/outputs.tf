# outputs.tf
# Define los valores de salida que se mostrarán después de un despliegue exitoso.

output "application_gateway_public_ip" {
  description = "La dirección IP pública del Application Gateway."
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "api_management_gateway_url" {
  description = "La URL del gateway de API Management."
  value       = azurerm_api_management.apim.gateway_url
}

output "spoke_resource_group_name" {
  description = "El nombre del grupo de recursos del Spoke."
  value       = azurerm_resource_group.spoke_rg.name
}

output "hub_resource_group_name" {
  description = "El nombre del grupo de recursos del Hub."
  value       = azurerm_resource_group.hub_rg.name
}
