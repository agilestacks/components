variable "allocated_storage" {
  default = "32"
}

variable "engine_version" {
  default = "11.4"
}

variable "instance_type" {
  default = "db.t2.micro"
}

variable "storage_type" {
  default = "gp2"
}

variable "vpc_id" {
  default = ""
}

variable "rds_name" {}

variable "database_name" {
  default = "postgres"
}

variable "database_password" {}

variable "database_username" {
  default = "postgres"
}

variable "database_port" {
  default = "5432"
}

variable "backup_retention_period" {
  default = "30"
}

variable "backup_window" {
  # 12:00AM-12:30AM ET
  default = "04:00-04:30"
}

variable "maintenance_window" {
  # SUN 12:30AM-01:30AM ET
  default = "sun:04:30-sun:05:30"
}

variable "auto_minor_version_upgrade" {
  default = true
}

variable "final_snapshot_identifier" {
  default = "terraform-aws-postgresql-rds-snapshot"
}

variable "skip_final_snapshot" {
  default = true
}

variable "copy_tags_to_snapshot" {
  default = true
}

variable "multi_availability_zone" {
  default = false
}

variable "storage_encrypted" {
  default = false
}

# variable "parameter_group" {
#   default = "default.postgres9.6"
# }

# variable "alarm_cpu_threshold" {
#   default = "85"
# }

# variable "alarm_disk_queue_threshold" {
#   default = "10"
# }

# variable "alarm_free_disk_threshold" {
#   # 500MB
#   default = "500000000"
# }

# variable "alarm_free_memory_threshold" {
#   # 128MB
#   default = "128000000"
# }

# variable "alarm_actions" {
#   type    = "list"
#   default = []
# }

variable "snapshot_identifier" {
  description = "Specify snapshot ID to restore DB from it, or leave empty for fresh DB instance."
  default = ""
}
