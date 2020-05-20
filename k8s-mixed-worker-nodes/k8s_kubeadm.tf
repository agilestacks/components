data "template_file" "kubeadm_join_config" {
  template = "${file("${path.module}/kubeadm/kubeadm-join.yaml")}"

  vars = {
    KUBEADM_TOKEN = var.kubeadm_token
    API_URL       = var.kube_apiserver_url
    ASG_NAME      = local.name2
  }
}

data "template_file" "kubeadm_join_service" {
  template = "${file("${path.module}/services/kbd-join.service")}"

  vars = {
    API_HOST       = replace(var.kube_apiserver_url, "/:\\d+$/", "")
  }
}
