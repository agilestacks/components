output "storage_account_name" {
  value = "${azurerm_storage_account.main.name}"
}

output "storage_account_region" {
  value = "${azurerm_storage_account.main.location}"
}

output "storage_container_name" {
  value = "${azurerm_storage_container.main.name}"
}

output "storage_primary_location" {
  value = "${azurerm_storage_account.main.primary_location}"
}

output "storage_primary_blob_endpoint" {
  value = "${azurerm_storage_account.main.primary_blob_endpoint}"
}

output "storage_primary_access_key" {
  value = "${azurerm_storage_account.main.primary_access_key}"
}

# output "storage_secondary_location" {
#   value = "${azurerm_storage_account.main.secondary_location}"
# }

# output "storage_secondary_blob_endpoint" {
#   value = "${azurerm_storage_account.main.secondary_blob_endpoint}"
# }
