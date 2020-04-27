terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

provider "aws" {
  alias  = "bucket"
  region = var.s3_bucket_region
}

provider "ignition" {
  version = "1.1.0"
}

provider "local" {
  version = "1.4.0"
}

provider "random" {
  version = "2.1.2"
}

provider "template" {
  version = "2.1.2"
}

resource "random_string" "rnd" {
  length = 4
  special = false
  upper = false
}

locals {
  worker_instance_types                 = var.instance_size
  worker_instance_type                  = split(":", local.worker_instance_types[0])[0]
  worker_instance_types_with_weights    = {
    for i in local.worker_instance_types:
      split(":", i)[0] => length(split(":", i)) > 1 ? split(":", i)[1] : "1"
  }

  name1 = "worker-${var.name}"
  name2 = "${substr(local.name1, 0, min(length(local.name1), 63))}"
  name_prefix     = "${substr(replace(local.name1, ".", "-"), 0, min(32, length(local.name1)-1))}"

  ami_id          = "${coalesce(var.ec2_ami_override, data.aws_ami.main.image_id)}"


  recent          = "${var.linux_version == "*"}"

  linux_version   = "${local.instance_gpu == true ? var.linux_gpu_version : var.linux_version }"


  ami_owners = "${map(
                "coreos", "595879546273",
                "flatcar", "075585003325",
              )}"
  ami_names = "${map(
                "coreos", "CoreOS-${var.linux_channel}-${local.linux_version}-*",
                "flatcar", "Flatcar-${var.linux_channel}-${local.linux_version}-*",
              )}"

  ami_owner = "${local.ami_owners[var.linux_distro]}"
  ami_name  = "${local.ami_names[var.linux_distro]}"

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
    {
      key                 = "superhub.io/stack/${var.domain_name}"
      value               = "owned"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/node-pool/kind"
      value               = "worker"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/node-pool/${var.domain_name}"
      value               = "owned"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/node-pool/name"
      value               = "${var.name}"
      propagate_at_launch = true
    },
  ]
  additional_tags = [
      {
        key                 = "k8s.io/cluster-autoscaler/enabled"
        value               = "true"
        propagate_at_launch = true
      },
  ]
  common_tags = "${map(
        "Name", "${local.name2}",
        "kubernetes.io/cluster/${var.cluster_tag}", "owned",
        "superhub.io/stack/${var.domain_name}", "owned"
    )}"

  tags = {
    default_tags = "${local.default_tags}"
    autoscaling_tags = concat(local.default_tags, local.additional_tags)
  }

  default_key          = "${var.domain_name}/stack-k8s-aws/ignition/ignition_worker.json"
  bootstrap_script_bucket = "${coalesce(replace(var.bootstrap_script_key, "/^s3://(.*?)/.*$/", "$1"), var.s3_bucket)}"
  bootstrap_script_key = "${coalesce(replace(var.bootstrap_script_key, "/^s3://.*?//", ""), local.default_key)}"
  dest_script_key      = "${dirname(local.bootstrap_script_key)}/pool/${var.name}/${basename(local.bootstrap_script_key)}"

  ignition_content = "${data.ignition_config.main.rendered}"
  filesystems = [
    "${local.instance_ephemeral_nvme
      ? data.ignition_filesystem.var_lib_docker.id
      : data.ignition_filesystem.ebs_mount.id}",
  ]

  arrays = [
    "${local.nvme_ndevices > 1 ? data.ignition_raid.nvme.id : ""}"
  ]

  sys_units = [
    "${local.instance_ephemeral_nvme
      ? data.ignition_systemd_unit.var_lib_docker.id
      : data.ignition_systemd_unit.ebs_mount.id}",
    "${data.ignition_systemd_unit.kubelet_ebs.id}",
    "${data.ignition_systemd_unit.docker_ebs.id}",
    "${local.instance_gpu == true ? data.ignition_systemd_unit.nvidia.id : ""}",
  ]

  files = [
    "${data.ignition_file.kubelet_config.id}"
  ]
  node_labels = [
    "name=${local.name1}",
    "${local.instance_gpu == true ? "gpu=true" : ""}",
  ]
}

data "aws_s3_bucket_object" "bootstrap_script" {
  provider = aws.bucket
  bucket   = local.bootstrap_script_bucket
  key      = local.bootstrap_script_key
}

resource "aws_s3_bucket_object" "bootstrap_script" {
  provider = aws.bucket
  bucket   = var.s3_bucket
  key      = local.dest_script_key

  content = replace(data.aws_s3_bucket_object.bootstrap_script.body,
      "--node-labels=node-role.kubernetes.io/node",
      "--node-labels=node-role.kubernetes.io/node,${join(",",compact(local.node_labels))}")


  content_type = "text/json"
  acl          = "private"
}

data "ignition_config" "main" {
  append {
    source = "s3://${aws_s3_bucket_object.bootstrap_script.bucket}/${aws_s3_bucket_object.bootstrap_script.key}"
    verification = "sha512-${sha512(aws_s3_bucket_object.bootstrap_script.content)}"
  }

  // hcl friendly working around conditional list values
  arrays      = "${compact(local.arrays)}"
  filesystems = "${compact(local.filesystems)}"
  systemd     = "${compact(local.sys_units)}"
  files       = "${compact(local.files)}"
  # directories = [
  #   "${data.ignition_directory.pods.id}",
  #   "${data.ignition_directory.docker.id}",
  # ]
  # links       = [
  #   "${data.ignition_link.pods.id}",
  #   "${data.ignition_link.docker.id}",
  # ]
}

data "aws_ami" "main" {
  owners      = ["${local.ami_owner}"]
  most_recent = "${local.recent}"

  filter {
    name   = "name"
    values = ["${local.ami_name}"]
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

resource "aws_launch_template" "worker_mixed_conf" {
  name_prefix = local.name_prefix

  network_interfaces {
    delete_on_termination       = "true"
    security_groups             = var.sg_ids
    associate_public_ip_address = true
  }

  iam_instance_profile {
    name = var.instance_profile
  }

  image_id      = local.ami_id
  instance_type = local.worker_instance_type
  key_name      = var.keypair


  user_data = base64encode(data.ignition_config.main.rendered)

  monitoring {
    enabled = "false"
  }
  block_device_mappings {
    device_name = local.device_root

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      iops                  = var.root_volume_type == "io1" ? var.root_volume_iops : 0
      encrypted             = "true"
      delete_on_termination = true
    }
  }
  block_device_mappings {
    device_name = local.device_name1
    ebs {
      volume_size           = var.ephemeral_storage_size
      volume_type           = var.ephemeral_storage_type
      iops                  = var.ephemeral_storage_type == "io1" ? var.ephemeral_storage_iops : 0
      encrypted             = "true"
      delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true

    # Ignore changes in the AMI which force recreation of the resource. This
    # avoids accidental deletion of nodes whenever a new CoreOS Release comes
    # out.
    ignore_changes = [image_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = local.common_tags
  }
  tag_specifications {
    resource_type = "volume"
    tags = local.common_tags
  }

  tags = local.common_tags

}

resource "aws_autoscaling_group" "workers" {
  name = local.name2

  # if autoscale not enabled then pool_max_size is 1 (default)
  max_size             = max(var.pool_max_count, var.pool_count)
  min_size             = var.pool_count
  desired_capacity     = var.pool_count
  vpc_zone_identifier   = var.subnet_ids
  termination_policies = ["ClosestToNextInstanceHour", "default"]

  # Because of https://github.com/hashifcorp/terraform/issues/12453 conditional operator cannot be used with list values
  # TODO: change this when will use terraform >=0.12
  tags = local.tags[var.autoscaling_enabled == "true" ? "autoscaling_tags" : "default_tags"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity = var.on_demand_base_capacity
      spot_allocation_strategy  = var.spot_allocation_strategy
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker_mixed_conf.id
        version = "$Latest"
      }

      dynamic "override" {
        for_each = local.worker_instance_types_with_weights
        content {
          instance_type     = override.key
          weighted_capacity = override.value
        }
      }

    }
  }

}

resource "aws_autoscaling_attachment" "workers" {
  count                  = length(var.load_balancers)
  autoscaling_group_name = aws_autoscaling_group.workers.name
  elb                    = var.load_balancers[count.index]
}

resource "local_file" "bootstrap_script" {
  content  = aws_s3_bucket_object.bootstrap_script.content
  filename = "${path.cwd}/.terraform/${var.name}-${random_string.rnd.result}.service"
  lifecycle {
    create_before_destroy = true
  }
}
