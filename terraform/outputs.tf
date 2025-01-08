output "backend_url" {
  description = "Backend App Service URL"
  value       = azurerm_app_service.backend.default_site_hostname
}

output "frontend_url" {
  description = "Frontend App Service URL"
  value       = azurerm_app_service.frontend.default_site_hostname
}
