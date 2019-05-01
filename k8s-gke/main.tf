provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

terraform {
  required_version = ">= 0.11.3"
  backend          "gcs"            {}
}
