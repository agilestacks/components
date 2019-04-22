terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.60.0"
}

data "aws_region" "current" {}

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

variable "vpc_id" {
  type = "string"
}

resource "aws_security_group" "efs" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "main" {
  creation_token = "${var.name}"

  tags {
    Name = "${var.name}"
  }

  performance_mode = "${var.performance_mode}"
}

resource "aws_efs_mount_target" "main" {
  file_system_id  = "${aws_efs_file_system.main.id}"
  subnet_id       = "${var.subnet}"
  security_groups = ["${aws_security_group.efs.id}"]
}

data "aws_subnet" "mount_target" {
  id = "${var.subnet}"
}

locals {
  dns = "${data.aws_subnet.mount_target.availability_zone}.${aws_efs_file_system.main.id}.efs.${data.aws_region.current.name}.amazonaws.com"
}

output "efs_endpoint" {
  value = "${local.dns}"
}

output "efs_id" {
  value = "${aws_efs_file_system.main.id}"
}
