
output "id" {
  value = "${azurerm_postgresql_server.main.id}"
}

output "hostname" {
  value = "${azurerm_postgresql_server.main.fqdn}"
}
