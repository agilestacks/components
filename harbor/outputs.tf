output "ingress_fqdn" {
  value = "${aws_route53_record.dns_app_ext.fqdn}"
}

output "load_balancer" {
  value = "${data.kubernetes_service.harbor_nginx.load_balancer_ingress.0.hostname}"
}
