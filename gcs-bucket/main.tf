terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}

locals {
  bucket = "${replace(lower(var.name), ".", "-")}"
}

resource "google_storage_bucket" "main" {
  name     = "${local.bucket}"
  location = "${var.location}"

  force_destroy = true
  versioning {
    enabled = false
  }
}
