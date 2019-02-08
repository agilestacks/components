terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "1.57.0"
}

provider "ignition" {
  version = "~> 1.0"
}

data "aws_s3_bucket_object" "bootstrap_script" {
  bucket = "${var.s3_bucket}"
  key    = "ignition_worker.json"
}

locals {
  gpu_instance_types = [
    "p3.2xlarge",
    "p3.8xlarge",
    "p3.16xlarge",
    "p3dn.24xlarge",
    "p2.xlarge",
    "p2.8xlarge",
    "p2.16xlarge",
    "g3s.xlarge",
    "g3.4xlarge",
    "g3.8xlarge",
    "g3.16xlarge",
  ]

  name1 = "worker-${var.name}"
  name2 = "${substring(local.name1, 0, min(length(local.name1),63))}"

  instance_gpu = "${contains(local.gpu_instance_types, var.instance_type)}"

  default_tags = [
    {
      key                 = "Name"
      value               = "${local.name2}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_tag}"
      value               = "owned"
      propagate_at_launch = true
    }
  ]

  autoscaling_tags = [
    "${local.default_tags}",
    { 
      key                 = "k8s.io/cluster-autoscaler/enabled", 
      value               = "true", 
      propagate_at_launch = true 
    }
  ]
}

resource "aws_s3_bucket_object" "bootstrap_script" {
  bucket  = "${var.s3_bucket}"
  key     = "k8s-worker-nodes/${var.name}/ignition_worker.json"
  content = "${local.instance_gpu ?
    replace(data.aws_s3_bucket_object.bootstrap_script.body,
      "--node-labels=node-role.kubernetes.io/node",
      "--node-labels=node-role.kubernetes.io/node,gpu=true") :
    data.aws_s3_bucket_object.bootstrap_script.body}"

  content_type = "text/json"
  acl          = "private"
}

data "ignition_systemd_unit" "nvidia" {
  name    = "nvidia.service"
  enabled = "${local.instance_gpu}"
  content = "${file("nvidia.service")}"
}

data "ignition_config" "main" {
  append {
    source = "${format("s3://%s/%s",
      "${var.s3_bucket}",
      "k8s-worker-nodes/${var.name}/ignition_worker.json")}"
  }

  systemd = [
    "${data.ignition_systemd_unit.nvidia.id}",
  ]
}

data "aws_ami" "coreos_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CoreOS-${var.container_linux_channel}-${local.instance_gpu == "true" ? format("%s-%s",var.container_linux_version_gpu,"*") : "*"}"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-id"
    values = ["595879546273"]
  }
}

resource "aws_launch_configuration" "worker_conf" {
  instance_type        = "${var.instance_type}"
  image_id             = "${coalesce(var.ec2_ami_override, data.aws_ami.coreos_ami.image_id)}"
  key_name             = "${var.keypair}"
  security_groups      = ["${var.sg_id}"]
  iam_instance_profile = "${var.instance_profile}"
  user_data            = "${data.ignition_config.main.rendered}"
  spot_price           = "${var.spot_price}"

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
  name                 = "${local.name2}"
  # if autoscale not enabled then pool_max_size is 1 (default)
  max_size             = "${max(var.pool_max_count, var.pool_count)}"
  min_size             = "${var.pool_count}"
  desired_capacity     = "${var.pool_count}"
  launch_configuration = "${aws_launch_configuration.worker_conf.id}"
  vpc_zone_identifier  = "${var.subnet_ids}"
  termination_policies = ["ClosestToNextInstanceHour", "default"]

  tags = "${var.autoscale_enabled == "true" ? local.autoscaling_tags : local.default_tags}"

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
