output "component.postgresql.rds.snapshot" {
  value = "${aws_db_snapshot.postgresql.id}"
}
