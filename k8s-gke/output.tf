output "api_ca_crt" {
  value = "file://${local_file.cluster_ca_certificate.filename}"
}

output "endpoint" {
  value = "${data.google_container_cluster.primary.endpoint}"
}
