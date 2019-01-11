terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "~> 1.30"
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
    "p2.xlarge",
    "p2.8xlarge",
    "p2.16xlarge",
    "p3.2xlarge",
    "p3.8xlarge",
    "p3.16xlarge",
    "g3.4xlarge",
    "g3.8xlarge",
    "g3.16xlarge",
  ]

  worker_instance_gpu = "${contains(local.gpu_instance_types, var.worker_instance_type)}"
}

resource "aws_s3_bucket_object" "bootstrap_script" {
  bucket = "${var.s3_bucket}"
  key    = "k8s-worker-nodes/${var.pool_name}/ignition_worker.json"

  content = "${local.worker_instance_gpu ?
    replace(data.aws_s3_bucket_object.bootstrap_script.body,
      "--node-labels=node-role.kubernetes.io/node",
      "--node-labels=node-role.kubernetes.io/node,gpu=true") :
    data.aws_s3_bucket_object.bootstrap_script.body}"

  content_type = "text/json"
  acl          = "private"
}

data "ignition_systemd_unit" "nvidia" {
  name    = "nvidia.service"
  enabled = "${local.worker_instance_gpu}"
  content = "${file("nvidia.service")}"
}

data "ignition_config" "main" {
  append {
    source = "${format("s3://%s/%s",
      "${var.s3_bucket}",
      "k8s-worker-nodes/${var.pool_name}/ignition_worker.json")}"
  }

  systemd = [
    "${data.ignition_systemd_unit.nvidia.id}",
  ]
}

data "external" "version" {
  program = ["sh", "-c", "curl https://${var.container_linux_channel}.release.core-os.net/amd64-usr/current/version.txt | sed -n 's/COREOS_VERSION=\\(.*\\)$/{\"version\": \"\\1\"}/p'"]
}

locals {
  json    = "${jsonencode(data.external.version.*.result)}"
  version = "${replace(local.json, "/.*\"version\":\"(.*)\".*/", "$1")}"
}

data "aws_ami" "coreos_ami" {
  filter {
    name   = "name"
    values = ["CoreOS-${var.container_linux_channel}-${local.worker_instance_gpu == "true" ? var.container_linux_version_gpu : local.version}-*"]
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
  instance_type        = "${var.worker_instance_type}"
  image_id             = "${coalesce(var.ec2_ami_override, data.aws_ami.coreos_ami.image_id)}"
  key_name             = "${var.keypair}"
  security_groups      = ["${var.worker_sg_id}"]
  iam_instance_profile = "${var.worker_instance_profile}"
  user_data            = "${data.ignition_config.main.rendered}"
  spot_price           = "${var.worker_spot_price}"

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

resource "aws_autoscaling_group" "workers" {
  name                 = "${substr(format("workers-%s-%s",var.pool_name,var.domain),0,min(63, length(format("workers-%s-%s",var.pool_name,var.domain))))}"
  desired_capacity     = "${var.worker_count}"
  max_size             = "${var.worker_count * 3}"
  min_size             = "${var.worker_count}"
  launch_configuration = "${aws_launch_configuration.worker_conf.id}"
  vpc_zone_identifier  = ["${split(",", coalesce(var.worker_subnet_ids, var.worker_subnet_id))}"]
  termination_policies = ["ClosestToNextInstanceHour", "default"]

  tags = [
    {
      key                 = "Name"
      value               = "worker-${var.pool_name}-${var.domain}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_tag}"
      value               = "owned"
      propagate_at_launch = true
    },
    "${var.autoscaling_group_extra_tags}",
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["tag"]
  }
}

resource "aws_autoscaling_attachment" "workers" {
  count                  = "${length(var.worker_load_balancers)}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  elb                    = "${var.worker_load_balancers[count.index]}"
}
