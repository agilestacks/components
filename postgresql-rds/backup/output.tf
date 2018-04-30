output "component.postgresql.rds.snapshot" {
  value = "${aws_db_snapshot.postgresql.id}"
}

output "component.postgresql.rds.version" {
  value = "${aws_db_snapshot.postgresql.engine_version}"
}
