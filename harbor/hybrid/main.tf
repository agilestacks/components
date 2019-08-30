terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

provider "kubernetes" {
  version        = "1.2.0"
  config_context = "${var.domain}"
}

locals {
  service_url = "https://${var.component}.${var.service_prefix}.${var.domain}"
  dockerconfigjson = <<EOS
    {"auths":{"${local.service_url}":{"username":"${var.username}","password":"${var.password}"}}}
EOS
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

resource "kubernetes_secret" "pull_secret" {
  metadata {
    name = "${var.pull_secret}"
    namespace = "${var.namespace}"
  }

  data {
    ".dockerconfigjson" = "${trimspace(local.dockerconfigjson)}"
  }

  type = "kubernetes.io/dockerconfigjson"
}
