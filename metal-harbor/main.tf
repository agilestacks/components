terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "1.41.0"
}

provider "kubernetes" {
  version        = "1.1.10"
  config_context = "${var.domain}"
}

data "aws_region" "current" {}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain}"
}

data "kubernetes_service" "harbor_nginx" {
  metadata {
    name      = "${var.nginx_service_name}"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_app_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.component}.${var.service_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.harbor_nginx.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

