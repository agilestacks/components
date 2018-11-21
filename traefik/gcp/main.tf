terraform {
  required_version = ">= 0.11.3"
  backend "gcs" {}
}

provider "google" {
  version = "1.19.1"
}

provider "kubernetes" {
  version        = "1.3.0"
  config_context = "${var.kubeconfig_context}"
}

provider "null" {
  version = "1.0.0"
}

data "google_dns_managed_zone" "ext_zone" {
  name = "${var.name}"
}

data "kubernetes_service" "traefik" {
  metadata {
    # https://github.com/helm/charts/blob/master/stable/traefik/templates/_helpers.tpl
    name      = "${var.component == "traefik" ? "traefik" : "${var.component}-traefik"}"
    namespace = "${var.namespace}"
  }
}

resource "google_dns_record_set" "dns_auth_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.auth_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  # lifecycle {
  #   ignore_changes = ["records", "ttl"]
  # }
}

resource "google_dns_record_set" "dns_app1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  # lifecycle {
  #   ignore_changes = ["records", "ttl"]
  # }
}

resource "google_dns_record_set" "dns_app2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  # lifecycle {
  #   ignore_changes = ["records", "ttl"]
  # }
}

resource "google_dns_record_set" "dns_apps1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  # lifecycle {
  #   ignore_changes = ["records", "ttl"]
  # }
}

resource "google_dns_record_set" "dns_apps2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  # lifecycle {
  #   ignore_changes = ["records", "ttl"]
  # }
}
