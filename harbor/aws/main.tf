terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "kubernetes" {
  version        = "1.2.0"
  config_context = "${var.domain}"
}

locals {
  dockerconfigjson = <<EOS
    {"auths":{"https://${var.component}.${var.service_prefix}.${var.domain}":{"username":"${var.username}","password":"${var.password}"}}}
EOS
}

resource "kubernetes_secret" "pull_secret" {
  metadata {
    name      = "${var.pull_secret}"
    namespace = "${var.namespace}"
  }

  data {
    ".dockerconfigjson" = "${trimspace(local.dockerconfigjson)}"
  }

  type = "kubernetes.io/dockerconfigjson"
}
