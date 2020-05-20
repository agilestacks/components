data "template_cloudinit_config" "worker" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init-boot.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_boot_worker.rendered
  }
}
