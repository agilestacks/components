terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

data "aws_region" "current" {}

provider "aws" {
  version = "2.35.0"
}

resource "aws_s3_bucket" "main" {
    bucket = "${var.bucket_name}"

    acl = "${var.acl}"

    force_destroy = true

    versioning {
        enabled = false
    }

    tags {
        Name = "${var.bucket_name}"
    }
}
