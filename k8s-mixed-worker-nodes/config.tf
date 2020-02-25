
locals {

  # derived from stack-k8s-aws. Code below shows exactly
  # how it is defaulted in stack-k8s-aws
  # see: https://github.com/agilestacks/stack-k8s-aws/blob/master/platforms/aws/config.tf#L111
  # see: https://github.com/agilestacks/stack-k8s-aws/blob/master/modules/bootkube/manifests.tf#L37

  default_dns_ip = "${cidrhost("10.3.0.0/16", 10)}"

  cluster_dns_ip = "${coalesce(var.service_dns_ip, local.default_dns_ip)}"
}

# Kubelet finetuning, such as GC options should be applied here
data "template_file" "kubelet_config" {
  template = "${file("${path.module}/kubernetes/kubelet-config.yaml")}"
  vars = {
    cluster_dns_ip = "${local.cluster_dns_ip}"
  }
}

data "ignition_file" "kubelet_config" {
  filesystem = "root"
  path       = "/var/lib/kubelet/config.yaml"
  mode       = 0644

  content {
    content = "${data.template_file.kubelet_config.rendered}"
  }
}
