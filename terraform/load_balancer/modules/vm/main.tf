
# LEVANTAR INTERFAZ DE RED. 
# El nic lo crea como un recurso independendiente
resource "azurerm_network_interface" "main" {
  name = var.nic_
  location = var.location_
  resource_group_name = var.resource_
  # Dejar en dinamica. Mirar como manejar DHCP
  ip_configuration {
    name = "internal"
    subnet_id = var.subnet_id_
    private_ip_address_allocation = "Dynamic" #STATIC
  } #maquina huerfana si no se configura el nic
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
      network_interface_id    = azurerm_network_interface.main.id
      ip_configuration_name   = "internal"
      backend_address_pool_id = var.poolID_
    }


resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = var.security_group_id_
}
# CREACION DE LA VM 
resource "azurerm_linux_virtual_machine" "main" {
  name = var.namevm_
  resource_group_name = var.resource_
  location = var.location_
  size = "Standard_B1s" # FREE_F1 no funciona
  admin_username = "adminuser"
  computer_name = var.namevm_
  availability_set_id = var.avalSetID_
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username = "adminuser"
    # Instalar ssh en el portatil de la empresa
    # ssh keygen -o
    public_key = file("~/.ssh/id_rsa.pub") #ssh-keygen windows 10
    # Creacion de .pem para conexion ssh externa en ../vm_public_ip
    # linux ssh-keygen -t rsa -C "email@domain.com"
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

