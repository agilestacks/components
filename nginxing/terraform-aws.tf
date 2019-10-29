terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "1.60.0"
}

provider "kubernetes" {
  version                  = "1.9.0"
  config_context_auth_info = "admin@${var.domain_name}"
  config_context_cluster   = "${var.domain_name}"
}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

data "kubernetes_service" "nginxing" {
  metadata {
    name      = "${var.component}-nginx-ingress-controller"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_url" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.nginxing.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_url_wildcard" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.nginxing.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}
