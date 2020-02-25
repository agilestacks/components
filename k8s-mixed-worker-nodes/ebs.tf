locals {
  device_root = "/dev/xvda"
  device_name1 = "/dev/xvdz"
  mount_path   = "/mnt/containers"
  mount_name   = "${join("-",compact(split("/", local.mount_path)))}.mount"
}

data "ignition_filesystem" "ebs_mount" {
  mount {
    device = "${local.device_name1}"
    format = "ext4"
  }
}

data "ignition_systemd_unit" "ebs_mount" {
  name    = "${local.mount_name}"
  enabled = true
  content = "${local_file.ebs_mount.content}"
}

data "ignition_systemd_unit" "kubelet_ebs" {
  name = "kubelet.service"
  dropin {
    name    = "20-wait-volume-mount.conf"
    content = "${local_file.kubelet_dropin.content}"
  }
}

data "ignition_systemd_unit" "docker_ebs" {
  name = "docker.service"
  dropin {
    name    = "10-wait-volume-mount.conf"
    content = "${local_file.docker_dropin.content}"
  }
}

resource "local_file" "ebs_mount" {
  filename = "${path.cwd}/.terraform/${random_string.rnd.result}.service"
  content  = <<EOF
[Unit]
Description=Mount ebs to ${local.mount_path}
Before=local-fs.target
[Mount]
What=${local.device_name1}
Where=${local.mount_path}
Type=ext4
[Install]
WantedBy=local-fs.target
EOF

  lifecycle {
    create_before_destroy = true
    ignore_changes = [filename]
  }
}

resource "local_file" "docker_dropin" {
  filename = "${path.cwd}/.terraform/${random_string.rnd.result}1.dropin"
  content  = <<EOF
[Unit]
After=${local.mount_name}
Requires=${local.mount_name}
[Service]
ExecStartPre=/usr/bin/mkdir -p ${local.mount_path}/docker
ExecStartPre=/usr/bin/mkdir -p /var/lib
ExecStartPre=/usr/bin/bash -c '/usr/bin/test -L /var/lib/kubelet || /usr/bin/ln -sfv ${local.mount_path}/docker /var/lib/docker'
EOF

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "local_file" "kubelet_dropin" {
  filename = "${path.cwd}/.terraform/${random_string.rnd.result}2.dropin"
  content  = <<EOF
[Unit]
After=${local.mount_name}
Requires=${local.mount_name}
[Service]
ExecStartPre=/usr/bin/bash -c '/usr/bin/test -d ${local.mount_path}/kubelet || /usr/bin/mv /var/lib/kubelet ${local.mount_path}/kubelet'
ExecStartPre=/usr/bin/bash -c '/usr/bin/test -L /var/lib/kubelet || /usr/bin/ln -sfv ${local.mount_path}/kubelet /var/lib/kubelet'
EOF

  lifecycle {
    ignore_changes = [filename]
  }
}
