terraform {
  required_version = ">= 0.11.10"
  backend          "s3"             {}
}

provider "aws" {
  version = "2.14.0"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}

data "aws_region" "current" {}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

data "kubernetes_service" "istio" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_url" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.istio.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_url_wildcard" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.istio.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}
