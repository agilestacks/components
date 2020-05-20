data "template_file" "cloud_init_boot_worker" {
  template = file("${path.module}/cloud-init/cloud-init-boot.yaml")

  vars = {
    K8S_VERSION         =  var.kubernetes_version
    S3_CLOUD_INIT_PATH  = "${var.s3_bucket}/${local.cloud_init_worker_upload_path}"
  }
}

data "template_file" "cloud_init_k8s_worker" {
  template = "${file("${path.module}/cloud-init/cloud-init-k8s-worker-init.yaml")}"
  vars = {
    API_URL          = var.kube_apiserver_url
    SYSTEMD_KBD_JOIN = base64encode(data.template_file.kubeadm_join_service.rendered)
    KUBEADM_JOIN     = base64encode(data.template_file.kubeadm_join_config.rendered)
  }
}