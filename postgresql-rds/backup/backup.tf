terraform {
  required_version = ">= 0.9.3"
}

provider "aws" {
  version = "1.23.0"
}

resource "aws_db_snapshot" "postgresql" {
  db_instance_identifier = "${var.rds_name}"
  db_snapshot_identifier = "${var.rds_name}-${replace(timestamp(), ":", "-")}"
}
