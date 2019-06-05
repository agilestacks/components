output "url" {
  value = "${azurerm_container_registry.main.name}.azurecr.io"
}

output "login_server" {
  value = "${azurerm_container_registry.main.login_server}"
}

output "username" {
  value = "${azurerm_container_registry.main.admin_username}"
}

output "password" {
  value = "${azurerm_container_registry.main.admin_password}"
}
