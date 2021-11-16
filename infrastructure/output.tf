output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "login_server" {
  value = azurerm_container_registry.example.login_server
}

output "app_name" {
  value       = azurerm_app_service.main.name
  description = "The name of the App Service."
}

output "yml_app" {
  value       = azurerm_app_service.main.site_config[0].linux_fx_version
  description = "The YML for Docker Compose."
}

output "hostname" {
  value       = azurerm_app_service.main.default_site_hostname
  description = "The default hostname for the App Service."
}

output "cosmos-db-endpoints_write" {
  value = azurerm_cosmosdb_account.db.write_endpoints
}

output "cosmos-db-primary_key" {
  sensitive = true
  value     = azurerm_cosmosdb_account.db.primary_key
}
