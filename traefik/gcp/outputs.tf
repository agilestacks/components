output "ingress_fqdn" {
  value = "${replace(google_dns_record_set.dns_app1_ext.name, "/\\.$/", "")}"
}

output "sso_ingress_fqdn" {
  value = "${replace(google_dns_record_set.dns_apps1_ext.name, "/\\.$/", "")}"
}

output "load_balancer" {
  value = "${data.kubernetes_service.traefik.load_balancer_ingress.0.ip}"
}

output "load_balancer_dns_record_type" {
  value = "A"
}
