# backend.tf
# Configura el estado remoto en un Azure Storage Account.
# NOTA: El resource group y el storage account para el backend deben crearse por separado
# y de antemano, ya que Terraform necesita el backend antes de poder gestionar recursos.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-corp"
    storage_account_name = "sttfstatecorp"
    container_name       = "tfstate"
    key                  = "corp.apim-platform.dev.terraform.tfstate"
  }
}
