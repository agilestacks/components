terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "1.35.0"
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
    "g3.4xlarge",
    "g3.8xlarge",
    "g3.16xlarge"
  ]
  worker_instance_gpu = "${contains(local.gpu_instance_types, var.worker_instance_type)}"
}

# https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
# GPU users must subscribe to https://aws.amazon.com/marketplace/pp?sku=58kec53jbhfbaqpgzivdyhdo9
# Region                            Amazon EKS-optimized AMI  with GPU support
# US West (Oregon) (us-west-2)      ami-08cab282f9979fc7a     ami-0d20f2404b9a1c4d1
# US East (N. Virginia) (us-east-1) ami-0b2ae3c6bda8b5c06     ami-09fe6fc9106bda972
# EU (Ireland) (eu-west-1)          ami-066110c1a7466949e     ami-09e0c6b3d3cf906f1
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-*", "amazon-eks-gpu-node-*"]
  }

  most_recent = true
  owners      = ["${local.worker_instance_gpu ? "679593333241" : "602401143452"}"] # Amazon
}

# https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-21/amazon-eks-nodegroup.yaml
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
  desired_capacity     = "${var.worker_count}"
  launch_configuration = "${aws_launch_configuration.node.id}"
  max_size             = 16
  min_size             = 1
  name                 = "eks-node-${local.name2}"
  vpc_zone_identifier  = ["${split(",", var.worker_subnet_ids)}"]

  tag {
    key                 = "Name"
    value               = "eks-node-${local.name2}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
