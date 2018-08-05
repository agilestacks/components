terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "~> 1.30"
  region  = "eu-central-1"
}

provider "archive" {
  version = "1.0.3"
}

provider "external" {
  version = "1.0.0"
}

provider "ignition" {
  version = "1.0.0"
}

provider "local" {
  version = "1.1.0"
}

provider "null" {
  version = "1.0.0"
}

provider "template" {
  version = "1.0.0"
}

provider "tls" {
  version = "1.0.1"
}

variable "worker_count" {
  type    = "string"
  default = "30"

  description = <<EOF
The number of worker nodes to be created.
This applies only to cloud platforms.
EOF
}

variable "asi_container_linux_channel" {
  type    = "string"
  default = "stable"

  description = <<EOF
(optional) The Container Linux update channel.

Examples: `stable`, `beta`, `alpha`
EOF
}

variable "asi_container_linux_version" {
  type    = "string"
  default = "1800.5.0"

  description = <<EOF
The Container Linux version to use. Set to `latest` to select the latest available version for the selected update channel.

Examples: `latest`, `1465.6.0`
EOF
}

variable "keypair" {
  type        = "string"
  description = "Name of an SSH key located within the AWS region. Example: coreos-user."
  default     = "agilestacks"
}

variable "worker_instance_type" {
  type        = "string"
  description = "Instance size for the master node(s). Example: `t2.small`."
  default     = "r4.large"
}

variable "worker_spot_price" {
  type        = "string"
  description = "Spot request price. Empty for on-demand"
  default     = "0.06"
}

variable "asi_aws_ec2_ami_override" {
  type        = "string"
  description = "(optional) AMI override for all nodes. Example: `ami-foobar123`."
  default     = ""
}

variable "asi_aws_worker_extra_sg_ids" {
  description = <<EOF
(optional) List of additional security group IDs for worker nodes.

Example: `["sg-51530134", "sg-b253d7cc"]`
EOF

  type    = "list"
  default = []
}

variable "asi_aws_extra_tags" {
  type        = "map"
  description = "(optional) Extra AWS tags to be applied to created resources."
  default     = {}
}

variable "asi_autoscaling_group_extra_tags" {
  type    = "list"
  default = []

  description = <<EOF
(optional) Extra AWS tags to be applied to created autoscaling group resources.
This is a list of maps having the keys `key`, `value` and `propagate_at_launch`.

Example: `[ { key = "foo", value = "bar", propagate_at_launch = true } ]`
EOF
}

variable "asi_aws_worker_root_volume_type" {
  type        = "string"
  default     = "gp2"
  description = "The type of volume for the root block device of worker nodes."
}

variable "asi_aws_worker_root_volume_size" {
  type        = "string"
  default     = "30"
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
}

variable "asi_aws_worker_root_volume_iops" {
  type    = "string"
  default = "100"

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF
}

variable "asi_aws_worker_load_balancers" {
  type    = "list"
  default = []

  description = <<EOF
(optional) List of ELBs to attach all worker instances to.
This is useful for exposing NodePort services via load-balancers managed separately from the cluster.

Example:
 * `["ingress-nginx"]`
EOF
}

variable "base_domain" {
  description = "describe your variable"
  default     = "default value"
}

variable "cluster_name" {
  type = "string"

  description = <<EOF
Name of existing Kubernetes cluster

Example:
 * `mycluster`
EOF
}

variable "node_type" {
  type = "string"

  description = <<EOF
Type of worker nodes beeing added to the existing cluster

Example:
 * `gpu`
EOF
}

variable "aws_s3_files_worker_bucket" {
  type = "string"

  description = <<EOF
Bucket name in S3 from where to download igniniton configuration of existing worker nodes in the cluster

Example:
 * `files.mycluster.myaccount.demo01.kubernetes.delivery`
EOF
}

variable "aws_worker_sg_ids" {
  type = "list"

  description = <<EOF
Security group where additional worker nodes will be joined. 
Example:
 * `["sg-a7c955cb"]`
EOF
}

variable "aws_worker_subnet_ids" {
  type = "list"

  description = <<EOF
Subnet where additional worker nodes will be joined. Example: `ami-foobar123`.
Example:
 * `["subnet-805f57eb"]` 
EOF
}

variable "aws_worker_iam_role" {
  type        = "string"
  description = "AWS IAM role of existing worker nodes"
}
