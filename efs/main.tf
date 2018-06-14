terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.23.0"
}

data "aws_region" "current" {}

# variable "aws_az" {
#   type = "string"
# }

variable "name" {
  type = "string"
}

variable "performance_mode" {
  type    = "string"
  default = "generalPurpose"
}

variable "subnet" {
  type = "string"
}

variable "sgs" {
  type = "string"
}

variable "cname_zone" {
  type = "string"
}

variable "cname_record" {
  type    = "string"
  default = "nfs"
}

resource "aws_efs_file_system" "main" {
  # do we really need to replace `.` with `-`?
  # https://docs.aws.amazon.com/efs/latest/ug/API_CreateFileSystem.html#efs-CreateFileSystem-request-CreationToken
  # creation_token = "${replace("${var.name}", ".", "-")}"
  creation_token = "${var.name}"

  tags {
    Name = "${var.name}"
  }

  performance_mode = "${var.performance_mode}"
}

resource "aws_efs_mount_target" "main" {
  file_system_id  = "${aws_efs_file_system.main.id}"
  subnet_id       = "${var.subnet}"
  security_groups = ["${split(",", var.sgs)}"]
}

locals {
  # https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
  dns = "${aws_efs_file_system.main.id}.efs.${data.aws_region.current.name}.amazonaws.com"
}

data "aws_route53_zone" "int_zone" {
  name         = "${var.cname_zone}"
  private_zone = true
}

resource "aws_route53_record" "nfs_cname" {
  zone_id = "${data.aws_route53_zone.int_zone.zone_id}"
  name    = "${var.cname_record}"
  type    = "CNAME"
  records = ["${local.dns}"]
  ttl     = "30"
}

output "efs_endpoint" {
  value = "${local.dns}"
}
