terraform {
  required_version = ">= 0.11.10"
  backend          "s3"             {}
}

provider "aws" {
  version = "2.14.0"
}

data "aws_region" "current" {}

# variable "aws_az" {
#   type = "string"
# }

variable "name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "subnet" {
  type = "string"
}

variable "sgs" {
  type = "string"
}

variable "performance_mode" {
  type    = "string"
  default = "generalPurpose"
}

variable "provisioned_throughput" {
  type    = "string"
  default = "0"
}

resource "aws_security_group" "efs" {
  count = "${var.sgs == "" ? 1 : 0}"

  name        = "${var.name}-inbound-nfs"
  description = "Allow inbound NFS traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "main" {
  # do we really need to replace `.` with `-`?
  # https://docs.aws.amazon.com/efs/latest/ug/API_CreateFileSystem.html#efs-CreateFileSystem-request-CreationToken
  # creation_token = "${replace("${var.name}", ".", "-")}"
  creation_token = "${var.name}"

  tags {
    Name = "${var.name}"
  }

  performance_mode                = "${var.performance_mode}"
  throughput_mode                 = "${var.provisioned_throughput > 0 ? "provisioned" : "bursting"}"
  provisioned_throughput_in_mibps = "${var.provisioned_throughput}"
}

resource "aws_efs_mount_target" "main" {
  file_system_id  = "${aws_efs_file_system.main.id}"
  subnet_id       = "${var.subnet}"
  security_groups = ["${concat(aws_security_group.efs.*.id, split(",", var.sgs))}"]
}

data "aws_subnet" "mount_target" {
  id = "${var.subnet}"
}

# https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
# https://docs.aws.amazon.com/efs/latest/ug/troubleshooting-efs-mounting.html#mount-fails-dns-name
# "${aws_efs_mount_target.main.dns_name}" # this will wait for mount target? - slower
# If there is no mount target in a particular zone, then regional `fs-...` name won't resolve.
# Export zone-specific DNS name to everyone.
output "efs_endpoint" {
  value = "${data.aws_subnet.mount_target.availability_zone}.${aws_efs_file_system.main.id}.efs.${data.aws_region.current.name}.amazonaws.com"
}

output "efs_id" {
  value = "${aws_efs_file_system.main.id}"
}
