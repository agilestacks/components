locals {
  instance_gpu = "${contains(local.gpu_instance_types, var.instance_type)}"
}

data "ignition_systemd_unit" "nvidia" {
  name    = "nvidia.service"
  enabled = "${local.instance_gpu}"
  content = "${file("nvidia.service")}"
}
