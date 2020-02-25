provider "azurerm" {
  version = "1.43.0"
  alias  = "client"

  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

locals {
  server_name = "${replace(var.server_name, "/[^[:alnum:]]+/", "-")}"
  # server_name = "${substr(local.server_name_long, 0, min(length(local.server_name_long), 63))}"
}

resource "azurerm_postgresql_server" "main" {
  name                = "${local.server_name}"
  location            = "${var.azure_location}"
  resource_group_name = "${var.azure_resource_group_name}"

  sku {
    name     = "${var.database_sku_name}"
    capacity = "${var.database_sku_capacity}"
    tier     = "${var.database_sku_tier}"
    family   = "${var.database_sku_family}"
  }

  storage_profile {
    storage_mb            = "${var.database_storage_mb}"
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${var.database_username}"
  administrator_login_password = "${var.database_password}"
  version                      = "${var.database_version}"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_postgresql_database" "main" {
  name                = "${var.database_name}"
  resource_group_name = "${azurerm_postgresql_server.main.resource_group_name}"
  server_name         = "${azurerm_postgresql_server.main.name}"
  charset             = "UTF8"
  collation           = "en_US"
}
