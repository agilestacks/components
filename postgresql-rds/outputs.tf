output "id" {
  value = "${aws_db_instance.postgresql.id}"
}

output "database_security_group_id" {
  value = "${aws_security_group.default.id}"
}

output "hosted_zone_id" {
  value = "${aws_db_instance.postgresql.hosted_zone_id}"
}

output "hostname" {
  value = "${aws_db_instance.postgresql.address}"
}

output "port" {
  value = "${aws_db_instance.postgresql.port}"
}

output "username" {
  value = "${aws_db_instance.postgresql.username}"
}
