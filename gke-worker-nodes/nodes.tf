data "google_container_cluster" "primary" {
  name     = "${var.cluster_name}"
  location = "${var.location}"
}

resource "google_container_node_pool" "pool" {
  name     = "${var.pool_name}"
  location = "${var.location}"
  cluster  = "${data.google_container_cluster.primary.name}"

  version = "${data.google_container_cluster.primary.node_version}"

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  node_config {
    preemptible  = "${var.preemptible}"
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.volume_size}"

    metadata {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = "${var.asi_oauth_scopes}"
  }
}
