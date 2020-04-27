terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

data "aws_vpc" "selected" {
  id = "${var.vpc_id}"
  default = "${var.vpc_id == "" ? "true" : ""}"
}

data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"
}

locals {
  rds_name_long = "${replace(var.rds_name, "/[^[:alnum:]]+/", "-")}"
  rds_name = "${substr(local.rds_name_long, 0, min(length(local.rds_name_long), 63))}"
  final_snapshot_identifier = "${replace(var.final_snapshot_identifier, "/[^[:alnum:]]+/", "-")}"
}

resource "aws_db_subnet_group" "all" {
  name_prefix = "${local.rds_name}"
  subnet_ids  = ["${data.aws_subnet_ids.selected.ids}"]

  tags {
    Name = "${local.rds_name}-all-subnets"
  }
}

resource "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.selected.id}"

  tags {
    Name = "${local.rds_name}-db"
  }

  ingress {
    from_port   = "${var.database_port}"
    to_port     = "${var.database_port}"
    protocol    = "TCP"
    cidr_blocks = ["${data.aws_vpc.selected.cidr_block}"]
  }

  # Note: Postgres only need TCP
  # ingress {
  #     from_port   = "${var.database_port}"
  #     to_port     = "${var.database_port}"
  #     protocol    = "UDP"
  #     cidr_blocks = ["${data.aws_vpc.selected.cidr_block}"]
  # }

  # Note: Postgres should not go outside by itself
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}

resource "aws_db_instance" "postgresql" {
  allocated_storage          = "${var.allocated_storage}"
  engine                     = "postgres"
  engine_version             = "${var.engine_version}"
  identifier                 = "${local.rds_name}"
  instance_class             = "${var.instance_type}"
  storage_type               = "${var.storage_type}"
  name                       = "${var.database_name}"
  password                   = "${var.database_password}"
  username                   = "${var.database_username}"
  backup_retention_period    = "${var.backup_retention_period}"
  backup_window              = "${var.backup_window}"
  maintenance_window         = "${var.maintenance_window}"
  auto_minor_version_upgrade = "${var.auto_minor_version_upgrade}"
  final_snapshot_identifier  = "${local.final_snapshot_identifier}"
  skip_final_snapshot        = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot      = "${var.copy_tags_to_snapshot}"
  multi_az                   = "${var.multi_availability_zone}"
  port                       = "${var.database_port}"
  vpc_security_group_ids     = ["${aws_security_group.default.id}"]
  db_subnet_group_name       = "${aws_db_subnet_group.all.name}"
 #parameter_group_name       = "${var.parameter_group}"
  storage_encrypted          = "${var.storage_encrypted}"

  snapshot_identifier = "${var.snapshot_identifier}"

  lifecycle {
    ignore_changes = ["snapshot_identifier", "password"]
  }

  tags {
    Name = "${local.rds_name}-rds"
  }
}

# resource "aws_cloudwatch_metric_alarm" "database_cpu" {
#   alarm_name          = "alarm${local.rds_name}DatabaseServerCPUUtilization"
#   alarm_description   = "Database server CPU utilization"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/RDS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "${var.alarm_cpu_threshold}"


#   dimensions {
#     DBInstanceIdentifier = "${aws_db_instance.postgresql.id}"
#   }


#   alarm_actions = ["${var.alarm_actions}"]
# }


# resource "aws_cloudwatch_metric_alarm" "database_disk_queue" {
#   alarm_name          = "alarm${local.rds_name}DatabaseServerDiskQueueDepth"
#   alarm_description   = "Database server disk queue depth"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "DiskQueueDepth"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "${var.alarm_disk_queue_threshold}"


#   dimensions {
#     DBInstanceIdentifier = "${aws_db_instance.postgresql.id}"
#   }


#   alarm_actions = ["${var.alarm_actions}"]
# }


# resource "aws_cloudwatch_metric_alarm" "database_disk_free" {
#   alarm_name          = "alarm${local.rds_name}DatabaseServerFreeStorageSpace"
#   alarm_description   = "Database server free storage space"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "FreeStorageSpace"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "${var.alarm_free_disk_threshold}"


#   dimensions {
#     DBInstanceIdentifier = "${aws_db_instance.postgresql.id}"
#   }


#   alarm_actions = ["${var.alarm_actions}"]
# }


# resource "aws_cloudwatch_metric_alarm" "database_memory_free" {
#   alarm_name          = "alarm${local.rds_name}DatabaseServerFreeableMemory"
#   alarm_description   = "Database server freeable memory"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "FreeableMemory"
#   namespace           = "AWS/RDS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "${var.alarm_free_memory_threshold}"


#   dimensions {
#     DBInstanceIdentifier = "${aws_db_instance.postgresql.id}"
#   }


#   alarm_actions = ["${var.alarm_actions}"]
# }
