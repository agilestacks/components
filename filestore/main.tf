terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}

resource "google_filestore_instance" "main" {
  name = "${var.name}"
  zone = "${var.zone}"
  tier = "${var.tier}"

  file_shares {
    name        = "${var.share_name}"
    capacity_gb = "${var.share_capacity}"
  }

  networks {
    network = "${var.network}"
    modes   = ["MODE_IPV4"]
  }
}
