terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}


data "aws_region" "current" {}

data "aws_autoscaling_groups" "worker_asg" {
  
  filter {
    name   = "key"
    values = ["k8s.io/node-pool/kind"]
  }
  filter {
    name = "value"
    values = ["!'worker'$"]
  }

  filter {
    name   = "key"
    values = ["k8s.io/node-pool/${var.cluster_name}"]
  }
  filter {
    name = "value"
    values = ["owned"]
  }
}

output "asg" {
  value = "${data.aws_autoscaling_groups.worker_asg.names}"
}


resource "aws_autoscaling_lifecycle_hook" "drain_hook" {
  name                   = "drain_hook"
  autoscaling_group_name = "${data.aws_autoscaling_groups.worker_asg.names[0]}"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 180
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}
