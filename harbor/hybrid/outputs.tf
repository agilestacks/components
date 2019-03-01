output "ingress_fqdn" {
  value = "${aws_route53_record.dns_app_ext.fqdn}"
}

output "pull_secret" {
  value = "${var.pull_secret}"
}
