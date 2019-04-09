output "api_ca_crt" {
  value = "file://${local_file.cluster_ca_certificate.filename}"
}

output "api_client_crt" {
  value = "file://${local_file.client_certificate.filename}"
}

output "api_client_key" {
  value = "file://${local_file.client_key.filename}"
}

output "host" {
  value = "${data.azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
}

output "fqdn" {
  value = "${data.azurerm_kubernetes_cluster.k8s.fqdn}"
}
