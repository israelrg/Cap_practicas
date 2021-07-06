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
	name = "isra_resource"
	location = "westeurope"
	tags = {
		entorno = var.env_
		tipo = "vm"
	}
}


# 1. CREACION DE LA VNET
resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}


# 2. CREACION DE LA SUBNET. MIRAR SI EL BALANCEADOR DE CARGA
# SE INSTALA EN VNET O SUBNET. 
resource "azurerm_subnet" "main" {
  name = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

# LEVANTAR INTERFACES DE RED. 
# DE MOMENTO SOLO LEVANTO UNA. PROBAR A CREAR 2
resource "azurerm_network_interface" "main" {
  name = "nic1"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # De momento esta e dinamica. Mirar como manejar DHCP
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic" #STATIC
  } #La conexion se tiene crear aqui. Si no supongo que lo que creas es una maquina huerfana
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "VM_prueba"
  resource_group_name = azurerm_resource_group.main.name
  location  = azurerm_resource_group.main.location
  size = "Free_F1" # FREE_F1 no funciona
  admin_username = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    # En el ordenador principal con linux creamos la clave publica.
    # Crear un entorno distinto para deplegarlo en windows
    # Instalar ssh en el portatil de la empresa
    # ssh keygen -o
    public_key = file("~/.ssh/id_rsa.pub") 
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" #Error de politicas con el tier Free F1
  }

  source_image_reference { #Probar si deja desplegar redhat o open suse.
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
