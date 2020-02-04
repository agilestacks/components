terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  version = "2.20.1"
  project = "${var.gcp_project_id}"
}

data "google_dns_managed_zone" "zone" {
  name = "${replace(var.domain_name, ".", "-")}"
}

resource "google_dns_record_set" "dns_auth" {
  managed_zone = "${data.google_dns_managed_zone.zone.name}"
  name         = "${var.url_prefix}.${data.google_dns_managed_zone.zone.dns_name}"
  type         = "${var.load_balancer_dns_record_type}"
  ttl          = 300
  rrdatas      = ["${var.load_balancer}"]
}
