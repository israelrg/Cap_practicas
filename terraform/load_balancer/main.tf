
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


/*
RESOURCES QUE NECESITAN DE ID COMO PARAMETRO
- frontend_ip_configuration IN azurrerm_lb
- azurerm_lb_backend_address_pool IN ID LOAD BALANCER
*/


resource "azurerm_resource_group" "main" {
  name     = "isra_resource"
  location = "westeurope"
  tags = {
    entorno = "test"
    tipo    = "vm"
  }
}

# CREACION DE UNA IP PUBLICA
resource "azurerm_public_ip" "main"{
    name = "publicIP"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    allocation_method = "Static"
}

# CREACION DEL LOAD BALANCER
resource "azurerm_lb" "main"{
    name = "myLoadBalancer"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    sku = "Basic"

    
    frontend_ip_configuration {
        name = "publicIPLoadBalancer"
        public_ip_address_id = azurerm_public_ip.main.id
    }
}

# BACK END POOL ASOCIADO A LAS MAQUINAS
/* EN TERRAFORM ES UN POCO DISTINTO A HACERLO GRAFICAMENTE
NECESITAMOS ASOCIAR LOS NIC DE LAS MAQUINAS VIRTUALES QUE
DE MOMENTO NO ESTAN CREADAS. NECESITAMOS ASOCIAR Y AGRUPAR
LOS NIC DE LA SUBNET SOBRE LOS QUE SE COLOCA EL BALACEADOR
DE CARGA. REQUIERE DE DOS PASOS ADICIONALES. LO PODEMOS
ENGANCHAR DIRECTAMENTE EN LA CREACION DE LAS VM
*/
resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "poolAdress"
}




# CREACION DE LA VNET
resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}

# CREACION DE LA SUBNET
resource "azurerm_subnet" "main" {
  name = "internal"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
}






/* NO ELIMINAR ------------------------------------------------------
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
NO ELIMINAR -----------------------------------------------------*/
