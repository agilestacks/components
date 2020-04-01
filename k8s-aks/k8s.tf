data "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  resource_group_name = var.aks_resource_group_name
}

resource "local_file" "cluster_ca_certificate" {
  content = base64decode(
    data.azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate,
  )
  filename = "${path.cwd}/.terraform/${var.name}.${var.base_domain}/cluster_ca_certificate.pem"
}

