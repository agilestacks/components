
variable "domain" {}

variable "record" {
  description = "name of dns record to create"
}
variable "ingress_static_ip" {
  type = "string"
}

variable "ingress_static_host" {
  type = "string"
}

terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain}"
}

locals {
  target = "${coalesce(var.ingress_static_ip, var.ingress_static_host)}"
  type = "${var.ingress_static_ip != "" ? "A" : "CNAME"}"
}

output "records" {
  value = "${local.target}"
}

output "zone_id" {
  value = "${data.aws_route53_zone.ext_zone.zone_id}"
}

resource "aws_route53_record" "main" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.record}"
  type    = "${local.type}"
  ttl     = "30"
  records = ["${local.target}"]

  lifecycle {
    ignore_changes = ["ttl"]
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.record}"
  type    = "${local.type}"
  ttl     = "30"
  records = ["${local.target}"]

  lifecycle {
    ignore_changes = ["ttl"]
  }
}
