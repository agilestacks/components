terraform {
  required_version = ">= 0.11.10"
}

provider "aws" {
  version = "2.43.0"
}

locals {
  rds_name_long = "${replace(var.rds_name, "/[^[:alnum:]]+/", "-")}"
  rds_name = "${substr(local.rds_name_long, 0, min(length(local.rds_name_long), 63))}"
}

resource "aws_db_snapshot" "postgresql" {
  db_instance_identifier = "${local.rds_name}"
  db_snapshot_identifier = "${local.rds_name}-${replace(timestamp(), ":", "-")}"
}
