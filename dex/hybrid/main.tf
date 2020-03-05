terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

data "aws_route53_zone" "zone" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "dns_auth" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "${var.load_balancer_dns_record_type}"
  ttl     = 300
  records = ["${var.load_balancer}"]
}
