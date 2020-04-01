output "id" {
  value = "${aws_db_instance.postgresql.id}"
}

output "database_security_group_id" {
  value = "${aws_security_group.default.id}"
}

output "hostname" {
  value = "${aws_db_instance.postgresql.address}"
}

output "port" {
  value = "${aws_db_instance.postgresql.port}"
}

output "name" {
  value = "${aws_db_instance.postgresql.name}"
}

output "username" {
  value = "${aws_db_instance.postgresql.username}"
}
