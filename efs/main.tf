terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.41.0"
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

data "aws_subnet" "mount_target" {
  id = "${var.subnet}"
}

locals {
  # https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
  # https://docs.aws.amazon.com/efs/latest/ug/troubleshooting-efs-mounting.html#mount-fails-dns-name
  # dns = "${aws_efs_mount_target.main.dns_name}" # this will wait for mount target? - slower
  # If there is no mount target in a particular zone, then `fs-...` won't resolve.
  # Export zone-specific DNS name to everyone.
  dns = "${data.aws_subnet.mount_target.availability_zone}.${aws_efs_file_system.main.id}.efs.${data.aws_region.current.name}.amazonaws.com"
}

output "efs_endpoint" {
  value = "${local.dns}"
}

output "efs_id" {
  value = "${aws_efs_file_system.main.id}"
}
