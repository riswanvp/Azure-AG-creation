terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~>3.0"
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "prod-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "vm.tfstate"
  }
}

provider "azurerm" {
  features {}
}


## Use existing Vnet & subnet
data "azurerm_virtual_network" "Vnet" {
    name = var.azurerm_virtual_network.name
    resource_group_name = var.azurerm_resource_group.name
}

data "azurerm_subnet" "public" {
    name = var.azurerm_subnet.name
    virtual_network_name = data.azurerm_virtual_network.Vnet.name
    resource_group_name = var.azurerm_resource_group.name

}



resource "azurerm_public_ip" "new-ag" {
  name                = "New-Ag-PublicIP"
  resource_group_name = var.azurerm_resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${data.azurerm_virtual_network.Vnet.name}-bepool"
  frontend_port_name             = "${data.azurerm_virtual_network.Vnet.name}-Frontend-port"
  frontend_ip_configuration_name = "${data.azurerm_virtual_network.Vnet.name}-FrontEnd-ip"
  http_setting_name              = "${data.azurerm_virtual_network.Vnet.name}-BE-http-stngs"
  listener_name                  = "${data.azurerm_virtual_network.Vnet.name}-http-lstnr"
  request_routing_rule_name      = "${data.azurerm_virtual_network.Vnet.name}-rqrt"
  redirect_configuration_name    = "${data.azurerm_virtual_network.Vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "New-ECOM-appgateway"
  resource_group_name = var.azurerm_resource_group.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = data.azurerm_subnet.public.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.new-ag.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
