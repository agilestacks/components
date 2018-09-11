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
    "g3.16xlarge"
  ]
  worker_instance_gpu = "${contains(local.gpu_instance_types, var.worker_instance_type)}"
}

resource "aws_s3_bucket_object" "bootstrap_script" {
  bucket       = "${var.s3_bucket}"
  key          = "k8s-worker-nodes/${var.pool_name}/ignition_worker.json"
  content      = "${local.worker_instance_gpu ?
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
    # https://github.com/terraform-providers/terraform-provider-ignition/issues/12
    source = "${format("s3://%s/%s",
      "${var.s3_bucket}",
      "k8s-worker-nodes/${var.pool_name}/ignition_worker.json")}"
  }

  systemd = [
    "${data.ignition_systemd_unit.nvidia.id}",
  ]
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
  instance_type        = "${var.worker_instance_type}"
  image_id             = "${coalesce(var.ec2_ami_override, data.aws_ami.coreos_ami.image_id)}"
  key_name             = "${var.keypair}"
  security_groups      = ["${var.worker_sg_id}"]
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
  name                 = "${substr(format("workers-%s-%s",var.pool_name,var.domain),0,min(63, length(format("workers-%s-%s",var.pool_name,var.domain))))}"
  desired_capacity     = "${var.worker_count}"
  max_size             = "${var.worker_count * 3}"
  min_size             = "${var.worker_count}"
  launch_configuration = "${aws_launch_configuration.worker_conf.id}"
  vpc_zone_identifier  = ["${var.worker_subnet_id}"]
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

resource "aws_iam_instance_profile" "worker_profile" {
  name = "${substr(format("worker-profile-%s-%s",var.pool_name,var.domain),0,min(63, length(format("worker-profile-%s-%s",var.pool_name,var.domain))))}"
  role = "${aws_iam_role.worker_role.name}"
}

resource "aws_iam_role" "worker_role" {
  name = "${substr(format("worker-role-%s-%s",var.pool_name,var.domain),0,min(63, length(format("worker-role-%s-%s",var.pool_name,var.domain))))}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com"}
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": { "Service": "batch.amazonaws.com"}
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {"AWS": "*"}
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "worker_policy" {
  name = "${substr(format("worker-policy-%s-%s",var.pool_name,var.domain),0,min(63, length(format("worker-policy-%s-%s",var.pool_name,var.domain))))}"
  role = "${aws_iam_role.worker_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "route53:*",
        "s3:*",
        "sts:*",
        "dynamodb:*"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action" : [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
