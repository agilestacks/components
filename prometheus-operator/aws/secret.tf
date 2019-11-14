provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.domain}"
}

provider "template" {
  version = "2.1.2"
}

data "template_file" "thanos_config" {
  template = "${file("${path.module}/resources/thanos-config.yaml")}"

  vars = {
    //access_key = "${aws_iam_access_key.main.id}"
    //secret_key = "${aws_iam_access_key.main.secret}"
    bucket_name = "${aws_s3_bucket.main.bucket}"

    s3_endpoint = "${var.endpoints[ data.aws_region.current.name ]}"
  }
}

resource "kubernetes_secret" "thanos_config" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = "${var.namespace}"
  }

  data {
    thanos.yaml = "${data.template_file.thanos_config.rendered}"
  }
}
