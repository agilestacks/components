terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}
