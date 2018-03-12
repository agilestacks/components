output "ingress_fqdn" {
  value = "${aws_route53_record.dns_url.fqdn}"
}

