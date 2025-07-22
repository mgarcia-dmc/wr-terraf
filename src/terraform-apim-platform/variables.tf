
# variables.tf
# Defines input variables for the Terraform configuration.

variable "env" {
  description = "The deployment environment (e.g., 'dev', 'qas', 'prd')."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
}

variable "resource_group_name_prefix" {
  description = "A prefix for the resource group names."
  type        = string
}

variable "apim_publisher_name" {
  description = "The name of the API Management publisher."
  type        = string
}

variable "apim_publisher_email" {
  description = "The email of the API Management publisher."
  type        = string
}

variable "hub_vnet_address_space" {
  description = "The address space for the Hub VNet."
  type        = list(string)
  default     = ["172.16.128.0/24"]
}

variable "spoke_vnet_address_space" {
  description = "The address space for the Spoke VNet."
  type        = list(string)
  default     = ["172.16.132.0/24"]
}
