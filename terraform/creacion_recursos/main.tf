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
	name = var.name
	location = var.location
	tags = {
		entorno = "test"
		tipo = "webapp"
	}
}

module "azureweb-israel" {
  source = "./modules/azureweb-israel"
  tier_ = var.tier_
  size_ = var.size_
}





/*
resource "azurerm_app_service_plan" "mywebapp" {
	name = "azuresp-israel"
	location = azurerm_resource_group.my_resource.location
	resource_group_name = azurerm_resource_group.my_resource.name
	
	sku {
		tier = var.tier_
		size = var.size_
	}
}
*/
