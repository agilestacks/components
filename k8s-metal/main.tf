terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "1.35.0"
}

# data "aws_region" "current" {}

# variables

variable "name" {
  description = "Desired DNS name of the cluster"
  type        = "string"
}

variable "base_domain" {
  description = "DNS base domain"
  type        = "string"
}

variable "bucket" {
  description = "S3 bucket name"
  type        = "string"
}

variable "api_ip" {
  description = "API endpoint IP address"
  type        = "string"
}

# S3

locals {
  default_bucket = "files.${var.name}.${var.base_domain}"
}

resource "aws_s3_bucket" "files" {
  bucket = "${coalesce(var.bucket, local.default_bucket)}"
  acl = "private"
  force_destroy = true
  lifecycle {
    ignore_changes = ["*"]
  }
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
  ttl     = "60"
  records = ["${aws_route53_zone.main.name_servers}"]
}

resource "aws_route53_record" "api" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "api"
  type    = "A"
  ttl     = "60"
  records = ["${var.api_ip}"]
}

# outputs

output "s3_bucket" {
  value = "${aws_s3_bucket.files.bucket}"
}

output "api_endpoint_a" {
  value = "${aws_route53_record.api.fqdn}"
}
