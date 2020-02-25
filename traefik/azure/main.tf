terraform {
  required_version = ">= 0.11.10"
  backend "azurerm" {}
}

provider "azurerm" {
  version = "1.43.0"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}

data "azurerm_dns_zone" "ext_zone" {
  name                = "${var.domain_name}"
  resource_group_name = "${var.azure_resource_group_name}"
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "${var.component == "traefik" ? "traefik" : "${var.component}-traefik"}"
    namespace = "${var.namespace}"
  }
}

resource "azurerm_dns_a_record" "dns_app1_ext" {
  name                = "${var.url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  records             = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "azurerm_dns_a_record" "dns_app2_ext" {
  name                = "*.${var.url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  records             = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "azurerm_dns_a_record" "dns_apps1_ext" {
  name                = "${var.sso_url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  records             = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "azurerm_dns_a_record" "dns_apps2_ext" {
  name                = "*.${var.sso_url_prefix}"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 300
  records             = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}
