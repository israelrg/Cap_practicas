
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
        name = var.publicIPName_
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
  loadbalancer_id     = azurerm_lb.main.id
  name                = "poolAdress"
}




# RECURSO DE ANALISIS DE ESTADO DE LOS POOL (sondeo)
resource "azurerm_lb_probe" "ssh" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "saludssh"
  port                = 22
}

resource "azurerm_lb_probe" "http" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "saludhttp"
  port                = 80
}

# CREACION DE RULES PARA LA RED DE NAT
  resource "azurerm_lb_rule" "lbnatrule_ssh" {
   resource_group_name            = azurerm_resource_group.main.name
   loadbalancer_id                = azurerm_lb.main.id
   name                           = "ssh"
   protocol                       = "Tcp"
   frontend_port                  = 22
   backend_port                   = 22
   backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
   frontend_ip_configuration_name = var.publicIPName_
   probe_id                       = azurerm_lb_probe.ssh.id
}

  resource "azurerm_lb_rule" "lbnatrule_http" {
   resource_group_name            = azurerm_resource_group.main.name
   loadbalancer_id                = azurerm_lb.main.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 80
   backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
   frontend_ip_configuration_name = var.publicIPName_
   probe_id                       = azurerm_lb_probe.http.id
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


resource "azurerm_network_security_group" "main" {
    name                = "myNetworkSecurityGroup"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# CREAMOS EL AVAILABILITY SET. ES NECESARIO PARA
# CREARLOS DENTRO DEL MISMO GRUPO
# VARIAS VM
resource "azurerm_availability_set" "main" {
  name                = "avalSet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

module "VM"{
    count = 1
    source = "./modules/vm"
    nic_   = "nic${count.index}"
    namevm_  = "VM${count.index}"
    resource_ = azurerm_resource_group.main.name
    location_ = azurerm_resource_group.main.location
    subnet_id_ = azurerm_subnet.main.id 
    security_group_id_ = azurerm_network_security_group.main.id
    poolID_ = azurerm_lb_backend_address_pool.main.id
    avalSetID_ = azurerm_availability_set.main.id
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


module "VM2" {
    source = "./modules/vm"
    nic_   = "nic2"
    namevm_  = "VM2"
    resource_ = azurerm_resource_group.main.name
    location_ = azurerm_resource_group.main.location
    subnet_id_ = azurerm_subnet.main.id 
}
NO ELIMINAR -----------------------------------------------------*/
