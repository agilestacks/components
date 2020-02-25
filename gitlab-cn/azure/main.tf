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

data "kubernetes_service" "gitlab" {
  metadata {
    name      = "${var.gitlab_ingress}"
    namespace = "${var.namespace}"
  }
}

resource "azurerm_dns_a_record" "dns_app1_ext" {
  name                = "registry"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 100
  records             = ["${data.kubernetes_service.gitlab.load_balancer_ingress.0.ip}"]
}

resource "azurerm_dns_a_record" "dns_app2_ext" {
  name                = "gitlab"
  zone_name           = "${data.azurerm_dns_zone.ext_zone.name}"
  resource_group_name = "${var.azure_resource_group_name}"
  ttl                 = 100
  records             = ["${data.kubernetes_service.gitlab.load_balancer_ingress.0.ip}"]
}
