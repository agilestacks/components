provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}

terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}
