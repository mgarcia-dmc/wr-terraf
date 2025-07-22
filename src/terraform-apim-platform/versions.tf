
# versions.tf
# Locks provider versions for consistent deployments.
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }
}

# Gets Azure client data to set the tenant_id in Key Vault.
data "azurerm_client_config" "current" {}
