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

variable "asi_extra_tags" {
  type        = "map"
  description = "(optional) Extra tags to be applied to created resources."
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
  tags = "${merge(map(
      "kubernetes.io/cluster/${var.cluster_name}-${var.base_domain}", "owned",
      "superhub.io/stack/${var.cluster_name}.${var.base_domain}", "owned",
      "Kind", "public",
    ), var.asi_extra_tags)}"
}

resource "aws_route53_record" "parent" {
  zone_id = "${data.aws_route53_zone.base.zone_id}"
  name    = "${var.name}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.main.name_servers}"]
  allow_overwrite = true
}

resource "aws_route53_record" "api" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "api"
  type    = "${local.type}"
  ttl     = "300"
  records = ["${var.api_host}"]
  allow_overwrite = true
}

# outputs

output "api_endpoint_a" {
  value = "${aws_route53_record.api.fqdn}"
}
