terraform {
  required_version = ">= 0.12"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

locals {
  version = "1.15"
  gpu_instance_types = [
    "p2.xlarge",
    "p2.8xlarge",
    "p2.16xlarge",
    "p3.2xlarge",
    "p3.8xlarge",
    "p3.16xlarge",
    "p3dn.24xlarge",
    "g3s.xlarge",
    "g3.4xlarge",
    "g3.8xlarge",
    "g3.16xlarge",
    "g4dn.xlarge",
    "g4dn.2xlarge",
    "g4dn.4xlarge",
    "g4dn.8xlarge",
    "g4dn.16xlarge",
    "g4dn.12xlarge",
    "g4dn.metal",
  ]

  name1 = replace(var.name, ".", "-")
  name2 = substr(local.name1, 0, min(length(local.name1), 63))

  instance_gpu = contains(local.gpu_instance_types, var.instance_type)

  default_tags = [
    {
      key                 = "Name"
      value               = "eks-node-${local.name2}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      value               = "owned"
      propagate_at_launch = true
    },
  ]

  autoscaling_tags = [
    {
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = "true"
      propagate_at_launch = true
    },
  ]

  tags = {
    default_tags     = local.default_tags
    autoscaling_tags = concat(local.default_tags, local.autoscaling_tags)
  }
}
