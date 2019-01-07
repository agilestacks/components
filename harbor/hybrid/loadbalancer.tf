variable "dns_record_addr" {
  type = "string"
  description = "FQDN"
  default = "default_value"
}

variable "ingress_static_ip" {
  type = "string"
}

resource "aws_route53_record" "dns_app_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.component}.${var.service_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

output "load_balancer" {
  value = "${var.ingress_static_ip}"
}
