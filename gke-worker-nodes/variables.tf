variable "cluster_name" {}
variable "location" {}
variable "pool_name" {}
variable "min_node_count" {}
variable "max_node_count" {}
variable "preemptible" {}
variable "node_machine_type" {}
variable "project" {}
variable "volume_size" {}

variable "asi_oauth_scopes" {
  type = "list"

  # https://developers.google.com/identity/protocols/googlescopes
  default = [
    "https://www.googleapis.com/auth/cloud-platform",
    # "https://www.googleapis.com/auth/cloud-platform.read-only",
    "https://www.googleapis.com/auth/bigquery",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/datastore",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/spanner.data",
    "https://www.googleapis.com/auth/sqlservice.admin",
  ]
}
