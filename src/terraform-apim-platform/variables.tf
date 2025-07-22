# variables.tf
# Define todas las variables de entrada para la configuración, haciéndola reutilizable.

variable "env" {
  description = "El entorno de despliegue (ej. dev, qas, prd)."
  type        = string
}

variable "location" {
  description = "La región de Azure para el despliegue."
  type        = string
}

variable "resource_group_name_prefix" {
  description = "Prefijo para los nombres de los grupos de recursos."
  type        = string
  default     = "rg-apim-platform"
}

variable "hub_vnet_address_space" {
  description = "Espacio de direcciones para la VNet del Hub."
  type        = list(string)
}

variable "spoke_vnet_address_space" {
  description = "Espacio de direcciones para la VNet del Spoke."
  type        = list(string)
}

variable "apim_publisher_name" {
  description = "Nombre del publicador para el servicio APIM."
  type        = string
}

variable "apim_publisher_email" {
  description = "Email del publicador para el servicio APIM."
  type        = string
}
