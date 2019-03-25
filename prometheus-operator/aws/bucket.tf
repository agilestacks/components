terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

data "aws_region" "current" {}

provider "aws" {
  version = "1.60.0"
}

resource "aws_s3_bucket" "main" {
    bucket = "${var.bucket_name}-${var.domain}"

    acl = "${var.acl}"

    force_destroy = true

    versioning {
        enabled = false
    }

    tags {
        Name = "${var.bucket_name}-${var.domain}"
    }
}
