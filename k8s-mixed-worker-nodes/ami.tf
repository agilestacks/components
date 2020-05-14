locals {
  recent = var.linux_version == "*"

  linux_version = local.instance_gpu == true ? var.linux_gpu_version : var.linux_version

  // ami_owners = {
  //   "coreos"  = "595879546273"
  //   "flatcar" = length(regexall("gov", data.aws_region.current.name)) > 0 ? "775307060209" : "075585003325"
  // }

  // ami_names = {
  //   "coreos"  = "CoreOS-${var.linux_channel}-${local.linux_version}-*"
  //   "flatcar" = "Flatcar-${var.linux_channel}-${local.linux_version}-*"
  // }

  // ami_owner = local.ami_owners[var.linux_distro]
  // ami_name  = local.ami_names[var.linux_distro]

  ami_owner = "099720109477"
  ami_name  = "ubuntu/images/hvm-ssd/ubuntu-${var.ubuntu_version}-amd64-server-*"
}


data "aws_ami" "main" {
  owners      = [local.ami_owner]
  most_recent = local.recent

  filter {
    name = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}