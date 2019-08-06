terraform {
  required_version = ">= 0.11.3"
}

provider "aws" {
  version = "2.14.0"
}

resource "aws_db_snapshot" "postgresql" {
  db_instance_identifier = "${var.rds_name}"
  db_snapshot_identifier = "${var.rds_name}-${replace(timestamp(), ":", "-")}"
}
