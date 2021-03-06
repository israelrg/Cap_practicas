# CREACION DE LA MAQUINA VIRTUAL CON CONEXION AL EXTERIOR
# NO SE CONFIGURA SISTEMA DE GESTION DE ARRANQUE Y DIAGNOSTICO
# MAIN ES LARGO. CREAR DIFERENTES MODULOS Y VARIABLES

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
    entorno = var.env_
    tipo    = "vm"
  }
}
#1.NIC
#2.VM
#3.VM DISK
#4.VNET
#5.PUBLIC_IP
#6.SECURITY GROUP

# 1. CREACION DE LA VNET
resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}


# 2. CREACION DE LA SUBNET. MIRAR SI EL BALANCEADOR DE CARGA
# SE INSTALA EN VNET CON MASCARA DE RED 16
resource "azurerm_subnet" "main" {
  name = "internal"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

# PUBLIC IP
resource "azurerm_public_ip" "main" {
    name = "myPublicIP"
    location = "westeurope" #ERROR SI LO COJE COMO VARIABLE
    resource_group_name = azurerm_resource_group.main.name
    allocation_method  = "Dynamic"
}

# SECURITY GROUP. SOLO PERMITIR CONEXSIONES EXTERNAS A LA MAQUINA POR SSH
# CONFIURACION PRESCIDIBLE. ABRIR 80 PARA HTTP. Necesario crear otro security rule
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


# LEVANTAR INTERFAZ DE RED. 
# El nic lo crea como un recurso independendiente
resource "azurerm_network_interface" "main" {
  name = "nic1"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Dejar en dinamica. Mirar como manejar DHCP
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id #Nos requiere el id de la subnet. 
    private_ip_address_allocation = "Dynamic" #STATIC
    public_ip_address_id = azurerm_public_ip.main.id #Se necesita id, no ip!!!!!!!!!!!!
  } #maquina huerfana si no se configura el nic
}

# SE ASOCIA EL NIC AL SECURITY_RESOURCES_GRUP UNA VEZ SE HAYA LEVANTADO
resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}

# CREACION DE LA VM 
resource "azurerm_linux_virtual_machine" "main" {
  name = "VM_prueba"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s" # FREE_F1 no funciona
  admin_username = "adminuser"
  computer_name = "vmprueba"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username = "adminuser"
    # Instalar ssh en el portatil de la empresa
    # ssh keygen -o
    public_key = file("~/.ssh/id_rsa.pub") #ssh-keygen windows 10
    # Creacion de .pem para conexion ssh externa en ../vm_public_ip
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS" #Error de politicas con el tier Free F1
  }

  source_image_reference { #Probar redhat
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
