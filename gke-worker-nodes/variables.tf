variable "cluster_name" {}
variable "location" {}
variable "pool_name" {}
variable "min_node_count" {}
variable "max_node_count" {}
variable "preemptible" {}
variable "node_machine_type" {}
variable "project" {}

variable "asi_oauth_scopes" {
  type = "list"

  default = [
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
  ]
}
