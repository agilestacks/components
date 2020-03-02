# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_BlockDeviceMapping.html
locals {
  instance_ephemeral_nvme = "${contains(local.nvme_instance_types, var.instance_size[0])}"
  complete_list = "${concat(local.nvme_instance_types, list(var.instance_size[0]))}"
  maybe_index = "${index(local.complete_list, var.instance_size[0])}"
  nvme_ndevices = "${local.nvme_ndevices_by_type[local.maybe_index >= length(local.nvme_instance_types) ? 0 : local.maybe_index + 1]}"
  final_nvme_device = "${local.nvme_ndevices > 1 ? "/dev/md/nvme" : "/dev/xvdb"}"
}

data "template_file" "ephemeral_nvme_devices" {
  template = "/dev/nvme$${index}n1"
  count    = "${local.nvme_ndevices}"

  vars = {
    index = "${count.index + 1}"
  }
}

data "ignition_raid" "nvme" {
  name = "nvme"
  level = "stripe"
  devices = "${data.template_file.ephemeral_nvme_devices.*.rendered}"
}

data "ignition_filesystem" "var_lib_docker" {
  mount {
    device = "${local.final_nvme_device}"
    format = "ext4"
    wipe_filesystem = true
    options = ["-F"]
  }
}

data "ignition_systemd_unit" "var_lib_docker" {
  name    = "var-lib-docker.mount"
  enabled = true
  content = "${local_file.systemd2.content}"
}

resource "local_file" "systemd2" {
  content  = replace(file("var-lib-docker.mount"), "$device", local.final_nvme_device)
  filename = "${path.cwd}/.terraform/systemd2-${random_string.rnd.result}.service"
  lifecycle {
    create_before_destroy = true
  }
}
