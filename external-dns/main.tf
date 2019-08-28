terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

variable "domain_name" {
  type = "string"
  description = "Domain name associated with R53 hosted zone"
}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

output "hosted_zone_id" {
  value = "${data.aws_route53_zone.ext_zone.zone_id}"
}

