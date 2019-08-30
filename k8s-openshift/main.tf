terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

variable "name" {
  description = "Desired DNS name of the cluster"
  type        = "string"
}

variable "base_domain" {
  description = "DNS base domain"
  type        = "string"
}

variable "api_fqdn" {
  description = "API endpoint fqdn"
  type        = "string"
}

variable "vpc_id" {
  type = "string"
}

# DNS
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
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.api_fqdn}"]
}

resource "aws_route53_zone" "internal" {
  name = "i.${var.name}.${data.aws_route53_zone.base.name}"

  # We can't be sure enableDnsHostnames, enableDnsSupport are set on the EKS VPC created
  # out of our control, but AWS EKS VPC example do have DNS options enabled.
  # Terraform aws_vpc resource:
  # enable_dns_hostnames = true
  # enable_dns_support   = true
  vpc {
    vpc_id = "${var.vpc_id}"
  }

  force_destroy = true
}

# outputs
output "api_endpoint_cname" {
  value = "${aws_route53_record.api.fqdn}"
}
