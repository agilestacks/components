terraform {
  required_version = ">= 0.11.10"
  backend          "s3"             {}
}

provider "aws" {
  version = "2.14.0"
}

data "aws_region" "current" {}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "dns_auth_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.auth_url_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

resource "aws_route53_record" "dns_app1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

resource "aws_route53_record" "dns_app2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

resource "aws_route53_record" "dns_apps1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.sso_url_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}

resource "aws_route53_record" "dns_apps2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.sso_url_prefix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.ingress_static_ip}"]
}
