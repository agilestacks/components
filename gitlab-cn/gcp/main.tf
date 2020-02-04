
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

data "kubernetes_service" "gitlab" {
  metadata {
    name      = "${var.gitlab_ingress}"
    namespace = "${var.namespace}"
  }
}
resource "google_dns_record_set" "dns_app1_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "gitlab.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "100"
  rrdatas      = ["${data.kubernetes_service.gitlab.load_balancer_ingress.0.ip}"]
}

resource "google_dns_record_set" "dns_app2_ext" {
  managed_zone = "${data.google_dns_managed_zone.ext_zone.name}"
  name         = "registry.${data.google_dns_managed_zone.ext_zone.dns_name}"
  type         = "A"
  ttl          = "100"
  rrdatas      = ["${data.kubernetes_service.gitlab.load_balancer_ingress.0.ip}"]
}
