output "ingress_fqdn" {
  value = "${aws_route53_record.dns_app1.fqdn}"
}

output "sso_ingress_fqdn" {
  value = "${aws_route53_record.dns_apps1.fqdn}"
}

output "elb_domain" {
  value = "${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"
}
