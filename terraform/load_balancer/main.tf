terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "isra_resource"
  location = "westeurope"
  tags = {
    entorno = "test"
    tipo    = "vm"
  }
}

# 1. CREACION DE LA VNET
resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}

# subnet
resource "azurerm_subnet" "main" {
  name = "internal"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

module "VM1"{
    source = "./modules/vm"
    nic_   = "nic1"
    namevm_  = "VM1"
    resource_ = azurerm_resource_group.main.name
    location_ = azurerm_resource_group.main.location
    subnet_id_ = azurerm_subnet.main.id 
}

module "VM2" {
    source = "./modules/vm"
    nic_   = "nic2"
    namevm_  = "VM2"
    resource_ = azurerm_resource_group.main.name
    location_ = azurerm_resource_group.main.location
    subnet_id_ = azurerm_subnet.main.id 
}

