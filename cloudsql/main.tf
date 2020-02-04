
terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}

provider "random" {
  version = "2.1.2"
}

resource "random_id" "db_name_suffix" {
  byte_length = 3
}

data "google_compute_network" "private" {
  name = "${var.network}"
}

resource "google_sql_database_instance" "main" {
  name = "${var.name}3-${random_id.db_name_suffix.hex}"
  region = "${var.region}"
  database_version = "${var.database_version}"

  settings {
    tier = "${var.tier}"
    disk_size = "${var.disk_size}"
    ip_configuration {
      # google_sql_database_instance.main: Error waiting for Create Instance: Failed to create subnetwork.
      #   Please create Service Networking connection with service 'servicenetworking.googleapis.com' from
      #   consumer project '...' network '...' again.
      # ipv4_enabled = "false"
      # private_network = "projects/${var.project}/global/networks/${data.google_compute_network.private.name}"
      ipv4_enabled = "true"
      authorized_networks = [{
        value = "0.0.0.0/0"
      }]
    }
  }
}

resource "google_sql_database" "users" {
  name      = "${var.database_name}"
  instance  = "${google_sql_database_instance.main.name}"
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

resource "google_sql_user" "admin" {
  name     = "${var.database_username}"
  instance = "${google_sql_database_instance.main.name}"
  password = "${var.database_password}"
}
