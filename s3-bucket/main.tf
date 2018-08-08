terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "~> 1.25"
}

variable "name" {
  type = "string"
  description = "Name of the bucket"
}

variable "acl" {
  type = "string"
  description = "S3 bucket ACL"
  default = "private"
}

resource "aws_s3_bucket" "main" {
    bucket = "${var.name}"

    acl = "${var.acl}"

    force_destroy = true

    versioning {
        enabled = false
    }

    tags {
        Name = "${var.name}"
    }
#    logging {
#       target_bucket = "${aws_s3_bucket.log_bucket.id}"
#       target_prefix = "log/"
#    }
}

output "bucket" {
  value = "${aws_s3_bucket.main.bucket}"
}

output "arn" {
  value = "${aws_s3_bucket.main.arn}"
}

output "domain" {
  value = "${aws_s3_bucket.main.bucket_domain_name}"
}

output "region" {
  value = "${aws_s3_bucket.main.region}"
}
