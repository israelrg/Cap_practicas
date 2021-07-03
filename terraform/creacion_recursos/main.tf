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

resource "azurerm_resource_group" "my_resource" {
	name = "azurerg-israel"
	location = "West Europe"
	tags = {
		entorno = "test"
		tipo = "webapp"
	}
}

resource "azurerm_app_service_plan" "mywebapp" {
	name = "azuresp-israel"
	location = azurerm_resource_group.my_resource.location
	resource_group_name = azurerm_resource_group.my_resource.name
	
	sku {
		tier = "Free"
		size = "F1"
	}
}

