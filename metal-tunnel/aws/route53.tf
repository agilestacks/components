terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.41.0"
}

provider "kubernetes" {
  version        = "1.2.0"
  config_context = "${var.domain}"
}


locals {
  elb = "${data.kubernetes_service.svc.load_balancer_ingress.0.hostname}"
}

data "kubernetes_service" "svc" {
  metadata {
    name      = "${var.service_name}"
    namespace = "${var.namespace}"
  }
}

data "aws_route53_zone" "main" {
  name = "${var.domain}"
}

resource "aws_route53_record" "main" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.record}"
  type    = "CNAME"
  ttl     = "30"
  records = ["${local.elb}"]

  lifecycle {
    ignore_changes = ["ttl"]
  }
}

#module "drop_nlb" {
#  source = "github.com/agilestacks/terraform-modules.git//elb-sweeper"
#  elb    = "${local.elb}"
#}