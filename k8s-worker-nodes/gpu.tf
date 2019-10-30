locals {
  instance_gpu = "${contains(local.gpu_instance_types, var.instance_type)}"
}

data "ignition_systemd_unit" "nvidia" {
  name    = "nvidia.service"
  enabled = "${local.instance_gpu}"
  content = "${local_file.systemd1.content}"
}

resource "local_file" "systemd1" {
  content  = "${file("nvidia.service")}"
  filename = "${path.cwd}/.terraform/systemd1-${random_string.rnd.result}.json"
  lifecycle {
    create_before_destroy = true
  }
}
