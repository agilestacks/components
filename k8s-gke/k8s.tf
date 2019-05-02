data "google_container_cluster" "primary" {
  name     = "${var.cluster_name}"
  location = "${var.location}"
}

resource "local_file" "cluster_ca_certificate" {
  content  = "${base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  filename = "${path.cwd}/.terraform/${var.cluster_name}.${var.base_domain}/cluster_ca_certificate.pem"
}
