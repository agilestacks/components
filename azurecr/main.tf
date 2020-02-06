provider "azurerm" {
  version = "1.43.0"
  alias  = "client"

  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

locals {
  registry_name_long = "${replace(var.registry_name, "/[^[:alnum:]]+/", "")}"
  registry_name = "${substr(local.registry_name_long, 0, min(length(local.registry_name_long), 50))}"
}

resource "azurerm_container_registry" "main" {
  name                = "${local.registry_name}"
  location            = "${var.azure_location}"
  resource_group_name = "${var.azure_resource_group_name}"
  admin_enabled       = true
  sku                 = "Standard"
}
