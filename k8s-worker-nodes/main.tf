terraform {
  required_version = ">= 0.11.10"
  backend          "s3"             {}
}

provider "aws" {
  version = "2.14.0"
}

provider "ignition" {
  version = "1.0.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_s3_bucket_object" "bootstrap_script" {
  bucket = "${var.s3_bucket}"
  key    = "ignition_worker.json"
}

locals {
  name1 = "worker-${var.name}"
  name2 = "${substr(local.name1, 0, min(length(local.name1), 63))}"

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
    },
  ]

  tags = {
    default_tags = "${local.default_tags}"

    autoscaling_tags = [
      "${local.default_tags}",
      {
        key                 = "k8s.io/cluster-autoscaler/enabled"
        value               = "true"
        propagate_at_launch = true
      },
    ]
  }
}

resource "aws_s3_bucket_object" "bootstrap_script" {
  bucket = "${var.s3_bucket}"
  key    = "k8s-worker-nodes/${var.name}/ignition_worker.json"

  content = "${local.instance_gpu ?
    replace(data.aws_s3_bucket_object.bootstrap_script.body,
      "--node-labels=node-role.kubernetes.io/node",
      "--node-labels=node-role.kubernetes.io/node,gpu=true") :
    data.aws_s3_bucket_object.bootstrap_script.body}"

  content_type = "text/json"
  acl          = "private"
}

data "ignition_config" "main" {
  append {
    source = "${format("s3://%s/%s",
      "${var.s3_bucket}",
      "k8s-worker-nodes/${var.name}/ignition_worker.json")}"
  }

  // conditional operator cannot be used with list values
  arrays      = ["${local.nvme[local.nvme_ndevices > 1 ? "raid" : "empty"]}"]
  filesystems = ["${local.nvme[local.instance_ephemeral_nvme ? "docker" : "empty"]}"]

  systemd = [
    "${data.ignition_systemd_unit.nvidia.id}",
    "${data.ignition_systemd_unit.var_lib_docker.id}",
  ]
}

data "aws_ami" "coreos_ami" {
  most_recent = true

  owners = ["595879546273"]

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
}

resource "aws_launch_configuration" "worker_conf" {
  instance_type        = "${var.instance_type}"
  image_id             = "${coalesce(var.ec2_ami_override, data.aws_ami.coreos_ami.image_id)}"
  key_name             = "${var.keypair}"
  security_groups      = ["${var.sg_ids}"]
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
  tags = "${local.tags[var.autoscale_enabled == "true" ? "autoscaling_tags" : "default_tags"]}"

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
