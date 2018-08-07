terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "~> 1.30"
}

data "ignition_config" "main" {
  replace {
    source = "${format("s3://%s/%s", var.s3_files_worker_bucket, "ignition_worker.json")}"
  }
}

data "aws_iam_role" "worker_role" {
  count = "${var.worker_iam_role == "" ? 0 : 1}"
  name  = "${var.worker_iam_role}"
}

data "aws_ami" "coreos_ami" {
  filter {
    name   = "name"
    values = ["CoreOS-${var.container_linux_channel}-${var.container_linux_version}-*"]
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
  name                 = "worker-conf-${var.node_pool_name}-${var.base_domain}"
  instance_type        = "${var.worker_instance_type}"
  image_id             = "${coalesce(var.ec2_ami_override, data.aws_ami.coreos_ami.image_id)}"
  key_name             = "${var.keypair}"
  security_groups      = "${var.worker_sg_ids}"
  iam_instance_profile = "${aws_iam_instance_profile.worker_profile.arn}"
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
  name                 = "workers-${var.node_pool_name}-${var.base_domain}"
  desired_capacity     = "${var.worker_instance_count}"
  max_size             = "${var.worker_instance_count * 3}"
  min_size             = "${var.worker_instance_count}"
  launch_configuration = "${aws_launch_configuration.worker_conf.id}"
  vpc_zone_identifier  = "${var.worker_subnet_ids}"
  termination_policies = ["ClosestToNextInstanceHour", "default"]

  tags = [
    {
      key                 = "Name"
      value               = "worker-${var.node_pool_name}-${var.base_domain}"
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
    ignore_changes        = ["min_size", "max_size", "desired_capacity", "tag"]
  }
}

resource "aws_autoscaling_attachment" "workers" {
  count                  = "${length(var.worker_load_balancers)}"
  autoscaling_group_name = "${aws_autoscaling_group.workers.name}"
  elb                    = "${var.worker_load_balancers[count.index]}"
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker-profile-${var.node_pool_name}-${var.base_domain}"
  role = "${join("|", data.aws_iam_role.worker_role.*.name)}"
}
