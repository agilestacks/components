terraform {
  required_version = ">= 0.11.0"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.10.0"
}

provider "kubernetes" {
  version                  = "1.0.1"
  config_context_auth_info = "admin@${var.domain_name}"
  config_context_cluster   = "${var.domain_name}"
}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

data "aws_route53_zone" "int_zone" {
  name         = "${var.domain_name}"
  private_zone = true
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "${var.component}"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_auth_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.auth_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_app1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_app2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_apps1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_apps2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

# Private records, for in-cluster usage
resource "aws_route53_record" "dns_auth_int" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "${var.auth_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_app1_ext" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_app2_ext" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_apps1_ext" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "aws_route53_record" "dns_apps2_ext" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "*.${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}
