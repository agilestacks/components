provider "google" {
  project = "${var.project}"
  version = "2.3.0"
}

terraform {
  required_version = ">= 0.11.3"
  backend          "gcs"            {}
}
