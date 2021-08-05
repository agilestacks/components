terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.52.0"
    }
  }
  required_version = ">= 0.15"
  backend "s3" {}
}

locals {
  version = var.k8s_version
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

  asg_default_tags = [
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

  asg_additional_autoscaling_tags = [
    {
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = "true"
      propagate_at_launch = true
    },
  ]

  asg_autoscaling_tags = concat(local.asg_default_tags, local.asg_additional_autoscaling_tags)
}
