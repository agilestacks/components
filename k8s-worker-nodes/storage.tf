locals {
  varlibkubeletpods_devicename = "/dev/xvdb"
  # varlibkubeletpods_devicename = "/dev/sdb"
}

data "ignition_filesystem" "varlibkubeletpods" {
  mount {
    device = "${local.varlibkubeletpods_devicename}"
    format = "ext4"
    label  = "pods"
  }
}

data "ignition_systemd_unit" "varlibkubeletpods" {
  name    = "var-lib-kubelet-pods.mount"
  enabled = true
  content = "${local_file.varlibkubeletpods.content}"
}

data "ignition_systemd_unit" "kubelet" {
  name = "kubelet.service"
  dropin {
    name = "10-wait-volume-mount.conf"
    content = "${local_file.kubelet_dropin.content}"
  }
}

resource "local_file" "varlibkubeletpods" {
  filename = "${path.cwd}/.terraform/${random_string.rnd.result}.service"
  content  = <<EOF
[Unit]
Description=Mount ebs to /var/lib/kubelet/pods
Before=local-fs.target
[Mount]
What=${local.varlibkubeletpods_devicename}
Where=/var/lib/kubelet/pods
Type=ext4
[Install]
WantedBy=local-fs.target
EOF

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["filename"]
  }
}

resource "local_file" "kubelet_dropin" {
  filename = "${path.cwd}/.terraform/${random_string.rnd.result}.dropin1"
  content  = <<EOF
[Unit]
After=var-lib-kubelet-pods.mount
Requires=var-lib-kubelet-pods.mount
EOF

  lifecycle {
    ignore_changes = ["filename"]
  }
}
