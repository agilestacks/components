terraform {
  required_version = ">= 0.11.3"
  backend          "gcs"             {}
}

provider "google" {
  version = "1.16.2"
}

provider "kubernetes" {
  version        = "1.1.10"
  config_context = "${var.domain_name}"
}

data "google_dns_managed_zone" "ext_zone" {
  name = "${var.name}"
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "${var.component}"
    namespace = "${var.namespace}"
  }
}

resource "google_dns_record_set" "dns_auth_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.auth_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "google_dns_record_set" "dns_app1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "google_dns_record_set" "dns_app2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "google_dns_record_set" "dns_apps1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "google_dns_record_set" "dns_apps2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "*.${var.sso_url_prefix}.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "300"
  rrdatas      = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}
