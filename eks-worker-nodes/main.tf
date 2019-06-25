terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

locals {
  version = "1.13"
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
# Kubernetes 1.13.7
# Region                                    Amazon EKS-optimized AMI  with GPU support
# US East (Ohio) (us-east-2)                ami-07ebcae043cf995aa     ami-01f82bb66c17faf20
# US East (N. Virginia) (us-east-1)         ami-08c4955bcc43b124e     ami-02af865c0f3b337f2
# US West (Oregon) (us-west-2)              ami-089d3b6350c1769a6     ami-08e5329e1dbf22c6a
# Asia Pacific (Mumbai) (ap-south-1)        ami-0410a80d323371237     ami-094beaac92afd72eb
# Asia Pacific (Tokyo) (ap-northeast-1)     ami-04c0f02f5e148c80a     ami-0f409159b757b0292
# Asia Pacific (Seoul) (ap-northeast-2)     ami-0b7997a20f8424fb1     ami-066623eb3f5a82878
# Asia Pacific (Singapore) (ap-southeast-1) ami-087e0fca60fb5737a     ami-0d660fb17b06078d9
# Asia Pacific (Sydney) (ap-southeast-2)    ami-082dfea752d9163f6     ami-0d11124f8f06f8a4f
# EU (Frankfurt) (eu-central-1)             ami-02d5e7ca7bc498ef9     ami-085b174e2e2b41f33
# EU (Ireland) (eu-west-1)                  ami-09bbefc07310f7914     ami-093009474b04965b3
# EU (London) (eu-west-2)                   ami-0f03516f22468f14e     ami-08a5d542db43e17ab
# EU (Paris) (eu-west-3)                    ami-051015c2c2b73aaea     ami-05cbcb1bc3dbe7a3d
# EU (Stockholm) (eu-north-1)               ami-0c31ee32297e7397d     ami-0f66f596ae68c0353
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
