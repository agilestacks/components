terraform {
  required_version = ">= 0.11.10"
  backend "azurerm" {}
}

provider "azurerm" {
  version = "1.43.0"
}

data "azurerm_dns_zone" "zone" {
  name                = "${var.domain_name}"
  resource_group_name = "${var.azure_resource_group_name}"
}

resource "azurerm_dns_a_record" "dns_auth_a" {
  count = "${var.load_balancer_dns_record_type == "A" ? 1 : 0}"

  name                = "${var.url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  records             = ["${var.load_balancer}"]
}

resource "azurerm_dns_cname_record" "dns_auth_cname" {
  count = "${var.load_balancer_dns_record_type == "CNAME" ? 1 : 0}"

  name                = "${var.url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  record              = "${var.load_balancer}"
}
