output "service_url" {
  description = "Application URL"
  value       = azurerm_app_service.my_webapp.location
}

/*
output "instance_ips" {
  value = azurerm_app_service_plan.mywebapp.web.*.public_ip
}
*/