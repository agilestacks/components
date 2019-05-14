terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.10.0"
}

locals {
  # TODO length
  name2 = "${replace("${var.domain}-${var.pool_name}", ".", "-")}"
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
    "g3.16xlarge"
  ]
  worker_instance_gpu = "${contains(local.gpu_instance_types, var.worker_instance_type)}"
}

# https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
# GPU users must subscribe to https://aws.amazon.com/marketplace/pp/B07GRHFXGM
# Kubernetes 1.11
# Region                             Amazon EKS-optimized AMI  with GPU support
# US West (Oregon)      (us-west-2)  ami-094fa4044a2a3cf52     ami-014f4e495a19d3e4f
# US East (N. Virginia) (us-east-1)  ami-0b4eb1d8782fc3aea     ami-08a0bb74d1c9a5e2f
# US East (Ohio)        (us-east-2)  ami-053cbe66e0033ebcf     ami-04a758678ae5ebad5
# EU (Ireland)          (eu-west-1)  ami-0a9006fb385703b54     ami-050db3f5f9dbd4439
# EU (Stockholm)        (eu-north-1) ami-082e6cf1c07e60241     ami-69b03e17
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.11-*", "amazon-eks-gpu-node-1.11-*"]
  }

  most_recent = true
  owners      = ["${local.worker_instance_gpu ? "679593333241" : "602401143452"}"] # Amazon
}

# https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-12-10/amazon-eks-nodegroup.yaml
locals {
  userdata = <<USERDATA
#!/bin/sh
exec /etc/eks/bootstrap.sh ${var.cluster_name}
USERDATA
}

resource "aws_launch_configuration" "node" {
  associate_public_ip_address = true
  iam_instance_profile        = "${var.worker_instance_profile}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.worker_instance_type}"
  key_name                    = "${var.keypair}"
  name_prefix                 = "eks-node-${local.name2}"
  security_groups             = ["${var.worker_sg_id}"]
  spot_price                  = "${var.worker_spot_price}"
  user_data_base64            = "${base64encode(local.userdata)}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["image_id"]
  }

  root_block_device {
    volume_type = "${var.worker_root_volume_type}"
    volume_size = "${var.worker_root_volume_size}"
    iops        = "${var.worker_root_volume_type == "io1" ? var.worker_root_volume_iops : 0}"
  }
}

resource "aws_autoscaling_group" "nodes" {
  launch_configuration = "${aws_launch_configuration.node.id}"
  max_size             = "${var.autoscaling_group_max_size}"
  min_size             = "${var.autoscaling_group_min_size}"
  name                 = "eks-node-${local.name2}"
  vpc_zone_identifier  = ["${split(",", var.worker_subnet_ids)}"]

  tags = [
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
    "${var.autoscaling_group_extra_tags}",
  ]
}
