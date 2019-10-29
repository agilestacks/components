terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

locals {
  version = "1.14"
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
  ]

  name1 = "worker-${var.name}"
  name2 = "${substr(local.name1, 0, min(length(local.name1), 63))}"

  instance_gpu = "${contains(local.gpu_instance_types, var.instance_type)}"

  default_tags = [
    {
      key                 = "Name"
      value               = "${local.name2}"
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
    default_tags     = "${local.default_tags}"
    autoscaling_tags = "${concat(local.default_tags, local.autoscaling_tags)}"
  }
}

# https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-${local.instance_gpu ? "gpu-" : ""}node-${local.version}-*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

# https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-nodegroup.yaml
locals {
  userdata = <<USERDATA
#!/bin/sh
exec /etc/eks/bootstrap.sh ${var.cluster_name}
USERDATA
}

resource "aws_launch_configuration" "worker_conf" {
  associate_public_ip_address = true
  iam_instance_profile        = "${var.instance_profile}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.keypair}"
  name_prefix                 = "eks-node-${local.name2}"
  security_groups             = ["${var.sg_ids}"]
  spot_price                  = "${var.spot_price}"
  user_data_base64            = "${base64encode(local.userdata)}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["image_id"]
  }

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
    iops        = "${var.root_volume_type == "io1" ? var.root_volume_iops : 0}"
  }
}

resource "aws_autoscaling_group" "workers" {
  name = "${local.name2}"

  # if autoscale not enabled then pool_max_size is 1 (default)
  max_size             = "${max(var.pool_max_count, var.pool_count)}"
  min_size             = "${var.pool_count}"
  desired_capacity     = "${var.pool_count}"
  launch_configuration = "${aws_launch_configuration.worker_conf.id}"
  vpc_zone_identifier  = "${var.subnet_ids}"
  termination_policies = ["ClosestToNextInstanceHour", "default"]

  # Because of https://github.com/hashicorp/terraform/issues/12453 conditional operator cannot be used with list values
  # TODO: change this when will use terraform >=0.12
  tags = ["${local.tags[var.autoscale_enabled == "true" ? "autoscaling_tags" : "default_tags"]}"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["tags"]
  }
}

resource "aws_autoscaling_attachment" "workers" {
  count                  = "${length(var.load_balancers)}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  elb                    = "${var.load_balancers[count.index]}"
}
