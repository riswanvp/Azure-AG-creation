##Resource group
variable "azurerm_resource_group" {
  description = "Production resource group" 
  default =  "Production-rg"
  type = string
}
## Region
variable "location" {
    description = "The region which resource ging to be launch"
    type = string
    default = "UAE North"
}
## Vnet
variable "azurerm_virtual_network" {
    description = "production private network"
    type = string
    default = "Vnet-prod"
}
## Subnet
variable "azurerm_subnet" {
    description = "production subnet"
    type = string
    default = "prod-subnet"
  
}
