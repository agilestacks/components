variable "dns_record_addr" {
  type = "string"
  description = "FQDN"
  default = "default_value"
}

variable "ingress_static_ip" {
  type = "string"
}

resource "aws_route53_record" "dns_auth_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.component}.${var.service_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

resource "aws_route53_record" "dns_app_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.component}.${var.auth_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.dns_record_addr}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}
