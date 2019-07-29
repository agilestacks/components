output "ingress_fqdn" {
  value = "${aws_route53_record.dns_app1_ext.fqdn}"
}

output "sso_ingress_fqdn" {
  value = "${aws_route53_record.dns_apps1_ext.fqdn}"
}

output "load_balancer" {
  value = "${var.ingress_static_ip}"
}

output "load_balancer_dns_record_type" {
  value = "A"
}
