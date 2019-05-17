output "host" {
  value = "${google_sql_database_instance.main.ip_address.0.ip_address}"
}

output "connection" {
  value = "${google_sql_database_instance.main.connection_name}"
}
