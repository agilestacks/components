data "google_dns_managed_zone" "base" {
  name    = "${replace(var.base_domain, ".", "-")}"
  project = "${var.project}"
}

resource "google_dns_managed_zone" "main" {
  name        = "${var.name}-${replace(var.base_domain, ".", "-")}"
  dns_name    = "${var.name}.${var.base_domain}."
  description = "${var.name} GKE Cluster DNS Zone"
  project     = "${var.project}"

  labels = {
    foo = "${var.name}"
  }
}

resource "google_dns_record_set" "parent" {
  name         = "${var.name}.${var.base_domain}."
  managed_zone = "${data.google_dns_managed_zone.base.name}"
  type         = "NS"
  ttl          = 300
  rrdatas      = ["${google_dns_managed_zone.main.name_servers}"]
}

resource "google_dns_record_set" "api" {
  name         = "api.${var.name}.${var.base_domain}."
  managed_zone = "${google_dns_managed_zone.main.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${data.google_container_cluster.primary.endpoint}"]
}
