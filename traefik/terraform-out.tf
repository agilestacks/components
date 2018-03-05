output "ingress_fqdn" {
  value = "${module.dns_app1.fqdn}"
}

output "sso_ingress_fqdn" {
  value = "${module.dns_apps1.fqdn}"
}

output "elb_domain" {
  value = "${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"
}
