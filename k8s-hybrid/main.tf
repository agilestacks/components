terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

# variables

variable "name" {
  description = "Desired DNS name of the cluster"
  type        = "string"
}

variable "base_domain" {
  description = "DNS base domain"
  type        = "string"
}

variable "api_host" {
  description = "API endpoint IP address or hostname"
  type        = "string"
}

# DNS

locals {
  type = "${replace(var.api_host, "/^[\\d.]+$/", "") == "" ? "A" : "CNAME"}"
}

data "aws_route53_zone" "base" {
  name = "${var.base_domain}"
}

resource "aws_route53_zone" "main" {
  name          = "${var.name}.${data.aws_route53_zone.base.name}"
  force_destroy = true
}

resource "aws_route53_record" "parent" {
  zone_id = "${data.aws_route53_zone.base.zone_id}"
  name    = "${var.name}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.main.name_servers}"]
}

resource "aws_route53_record" "api" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "api"
  type    = "${local.type}"
  ttl     = "300"
  records = ["${var.api_host}"]
}

# outputs

output "api_endpoint_a" {
  value = "${aws_route53_record.api.fqdn}"
}
