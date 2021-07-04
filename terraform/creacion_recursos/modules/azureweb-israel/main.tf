
resource "azurerm_app_service_plan" "mywebapp" {
	name = "azureweb-israel"
	location = "West Europe"
    resource_group_name = "azurerg-israel"
	sku {
		tier = var.tier_
		size = var.size_
	}
}