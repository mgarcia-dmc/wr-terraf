# versions.tf
# Bloquea las versiones de los proveedores para despliegues consistentes.
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }
}

# Obtiene datos del cliente de Azure para configurar el tenant_id en Key Vault.
data "azurerm_client_config" "current" {}
