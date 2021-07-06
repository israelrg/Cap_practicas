
resource "azurerm_app_service_plan" "my_service_plan" {
	name = "azureweb-israel"
	location = "West Europe"
    resource_group_name = "azurerg-israel"
	sku {
		tier = var.tier_
		size = var.size_
	}
}


resource "azurerm_app_service" "my_webapp" {
	name = "myapppppp"
	location = "West Europe"
	resource_group_name = "azurerg-israel"
	app_service_plan_id = azurerm_app_service_plan.my_service_plan.id
}


