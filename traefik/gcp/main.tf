terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  version = "2.20.1"
  project = "${var.gcp_project_id}"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}

provider "null" {
  version = "2.1.2"
}

data "google_dns_managed_zone" "ext_zone" {
  name = "${replace(var.domain_name, ".", "-")}"
}

data "kubernetes_service" "traefik" {
  metadata {
    # https://github.com/helm/charts/blob/master/stable/traefik/templates/_helpers.tpl
    name      = "${var.component == "traefik" ? "traefik" : "${var.component}-traefik"}"
    namespace = "${var.namespace}"
  }
}

resource "google_dns_record_set" "dns_app1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "google_dns_record_set" "dns_app2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "google_dns_record_set" "dns_apps1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}

resource "google_dns_record_set" "dns_apps2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]
}
