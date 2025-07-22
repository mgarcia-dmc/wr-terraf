
# outputs.tf
# Defines the output values from our infrastructure.

output "application_gateway_public_ip" {
  description = "The public IP address of the Application Gateway."
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "api_management_gateway_url" {
  description = "The gateway URL of the API Management service."
  value       = azurerm_api_management.apim.gateway_url
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = azurerm_key_vault.main.vault_uri
  sensitive   = true
}
