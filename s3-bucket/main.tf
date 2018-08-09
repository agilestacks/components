terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

variable "endpoints" {
  type    = "map"
  description = "S3 service endpoints by region"
  default = {
    us-east-1 = "s3.amazonaws.com"
    us-east-2 = "s3-us-east-2.amazonaws.com"
    us-west-2 = "s3-us-west-2.amazonaws.com"
    us-west-1 = "s3-us-west-1.amazonaws.com"
    ca-central-1 = "s3-ca-central-1.amazonaws.com"
    eu-west-1 = "s3-eu-west-1.amazonaws.com"
    eu-west-2 = "s3-eu-west-2.amazonaws.com"
    eu-west-3 = "s3-eu-west-3.amazonaws.com"
    eu-central-1 = "s3-eu-central-1.amazonaws.com"
    ap-south-1 = "s3-ap-south-1.amazonaws.com"
    ap-southeast-1 = "s3-ap-southeast-1.amazonaws.com"
    ap-southeast-2 = "s3-ap-southeast-2.amazonaws.com"
    ap-northeast-1 = "s3-ap-northeast-1.amazonaws.com"
    ap-northeast-2 = "s3-ap-northeast-2.amazonaws.com"
    sa-east-1 = "s3-sa-east-1.amazonaws.com"
    us-gov-west-1 = "s3-us-gov-west-1.amazonaws.com"
    cn-north-1 = "s3.cn-north-1.amazonaws.com.cn"
    cn-northwest-1 = "s3.cn-northwest-1.amazonaws.com.cn"
  }
}

data "aws_region" "current" {
  current = true
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

output "endpoint" {
  value = "${var.endpoints[ data.aws_region.current.name ]}"
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
