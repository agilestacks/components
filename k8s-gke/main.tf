provider "google" {
  project = "${var.project}"
  version = "2.17.0"
}

terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}
