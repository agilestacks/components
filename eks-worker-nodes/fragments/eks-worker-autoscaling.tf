# https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-${local.instance_gpu ? "gpu-" : ""}node-${local.version}-*"]
  }

  most_recent = true
  owners      = ["amazon", "151742754352"] # GovCloud
}

# https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-nodegroup.yaml
locals {
  userdata = <<USERDATA
#!/bin/sh
${var.bootstrap}
exec /etc/eks/bootstrap.sh${length(var.labels) > 0 ? " --kubelet-extra-args --node-labels=${var.labels}" : ""} ${var.cluster_name}
USERDATA

}

locals {
  worker_instance_types                 = split(",", var.instance_type)
  worker_instance_type                  = split(":", local.worker_instance_types[0])[0]
  worker_instance_types_with_weights    = {
    for i in local.worker_instance_types:
      split(":", i)[0] => length(split(":", i)) > 1 ? split(":", i)[1] : "1"
  }
  worker_launch_template_trigger        = length(local.worker_instance_types) > 1 ? [] : [1]
  worker_mixed_instances_policy_trigger = length(local.worker_instance_types) > 1 ? [1] : []
}

resource "aws_launch_template" "node" {
  name_prefix = "eks-node-${local.name2}"

  image_id      = data.aws_ami.eks_worker.id
  instance_type = local.worker_instance_type
  key_name      = var.keypair
  user_data     = base64encode(local.userdata)

  # vpc_security_group_ids = var.sg_ids

  lifecycle {
    ignore_changes = [image_id]
  }

  block_device_mappings {
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
      iops        = var.root_volume_type == "io1" ? var.root_volume_iops : 0

      delete_on_termination = true
      encrypted             = true
    }
  }
  iam_instance_profile {
    name = var.instance_profile
  }
  dynamic "instance_market_options" {
    for_each = local.worker_launch_template_trigger
    content {
      market_type = "spot"
      spot_options {
        max_price = var.spot_price
      }
    }
  }
  monitoring {
    enabled = false
  }
  network_interfaces {
    # associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = var.sg_ids
  }
  # tag_specifications {
  #   resource_type = "instance"
  #   tags = {
  #     Name = "test"
  #   }
  # }
  # tag_specifications {
  #   resource_type = "volume"
  # }
}

resource "aws_autoscaling_group" "nodes" {
  name = "eks-node-${local.name2}"

  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.pool_count
  min_size            = 1
  max_size            = max(var.pool_max_count, var.pool_count)

  # either launch template or mixed instance policy is activated
  dynamic "launch_template" {
    for_each = local.worker_launch_template_trigger
    content {
      id      = aws_launch_template.node.id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = local.worker_mixed_instances_policy_trigger
    content {
      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.spot_allocation_strategy
        spot_instance_pools                      = var.spot_allocation_strategy == "lowest-price" ? var.spot_instance_pools : 0
        spot_max_price                           = var.spot_price
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.node.id
          version            = "$Latest"
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

  tags = var.autoscaling_enabled ? local.asg_autoscaling_tags : local.asg_default_tags

  # lifecycle {
  #   create_before_destroy = true
  #   ignore_changes        = [tags]
  # }
}

resource "aws_autoscaling_attachment" "nodes" {
  count                  = length(var.load_balancers)
  autoscaling_group_name = aws_autoscaling_group.nodes.name
  elb                    = var.load_balancers[count.index]
}
