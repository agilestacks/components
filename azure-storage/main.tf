provider "azurerm" {
  version = "1.43.0"
  alias  = "client"

  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

locals {
  account_name_long = "${replace(var.account_name, "/[^[:alnum:]]+/", "")}"
  account_name = "${substr(local.account_name_long, 0, min(length(local.account_name_long), 24))}"
}

resource "azurerm_storage_account" "main" {
  name                     = "${local.account_name}"
  location                 = "${var.azure_location}"
  resource_group_name      = "${var.azure_resource_group_name}"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "main" {
  name                  = "${var.container_name}"
  resource_group_name   = "${var.azure_resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.main.name}"
  container_access_type = "private"
}
