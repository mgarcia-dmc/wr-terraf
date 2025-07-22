# environments/dev.tfvars
# Valores específicos para el entorno de DESARROLLO.
# Para desplegar en otro entorno (ej. qas), crea un qas.tfvars y ejecútalo con:
# terraform apply -var-file="environments/qas.tfvars"

env                      = "dev"
location                 = "East US 2"
resource_group_name_prefix = "rg-apim-corp"
hub_vnet_address_space   = ["172.16.128.0/22"]
spoke_vnet_address_space = ["172.16.132.0/22"]
apim_publisher_name      = "Corporativo TI"
apim_publisher_email     = "ti.corp@example.com"
