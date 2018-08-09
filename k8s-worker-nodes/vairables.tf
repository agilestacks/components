variable "worker_instance_count" {
  type    = "string"
  default = "30"

  description = <<EOF
The number of worker nodes to be created.
This applies only to cloud platforms.
EOF
}

variable "container_linux_channel" {
  type    = "string"
  default = "stable"

  description = <<EOF
(optional) The Container Linux update channel.

Examples: `stable`, `beta`, `alpha`
EOF
}

variable "container_linux_version" {
  type    = "string"
  default = "1800.5.0"

  description = <<EOF
(optional) The Container Linux version to use. Set to `latest` to select the latest available version for the selected update channel.

Examples: `latest`, `1465.6.0`
EOF
}

variable "keypair" {
  type        = "string"
  default     = "agilestacks"
  description = "Name of an SSH key located within the AWS region. Example: coreos-user."
}

variable "worker_instance_type" {
  type        = "string"
  default     = "r4.large"
  description = "Instance size for the worker node(s). Example: `t2.small`."
}

variable "worker_instance_gpu" {
  type        = "string"
  default     = "false"
  description = "Whatever instance should have Nvidia driver inserted"
}

variable "worker_spot_price" {
  type        = "string"
  default     = "0.06"
  description = "Spot request price. Empty for on-demand"
}

variable "ec2_ami_override" {
  type        = "string"
  default     = ""
  description = "(optional) AMI override for all nodes. Example: `ami-foobar123`."
}

variable "worker_extra_sg_ids" {
  type    = "list"
  default = []

  description = <<EOF
(optional) List of additional security group IDs for worker nodes.

Example: `["sg-51530134", "sg-b253d7cc"]`
EOF
}

variable "extra_tags" {
  type        = "map"
  default     = {}
  description = "(optional) Extra AWS tags to be applied to created resources."
}

variable "autoscaling_group_extra_tags" {
  type    = "list"
  default = []

  description = <<EOF
(optional) Extra AWS tags to be applied to created autoscaling group resources.
This is a list of maps having the keys `key`, `value` and `propagate_at_launch`.

Example: `[ { key = "foo", value = "bar", propagate_at_launch = true } ]`
EOF
}

variable "worker_root_volume_type" {
  type        = "string"
  default     = "gp2"
  description = "The type of volume for the root block device of worker nodes."
}

variable "worker_root_volume_size" {
  type        = "string"
  default     = "30"
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
}

variable "worker_root_volume_iops" {
  type    = "string"
  default = "100"

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF
}

variable "worker_load_balancers" {
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
  type        = "string"
  description = "Base domain of a stack"
}

variable "node_pool_name" {
  type = "string"

  description = <<EOF
Type of worker nodes beeing added to the existing cluster

Example:
 * `gpu`
EOF
}

variable "s3_files_worker_bucket" {
  type = "string"

  description = <<EOF
Bucket name in S3 from where to download igniniton configuration of existing worker nodes in the cluster

Example:
 * `files.mycluster.myaccount.demo01.kubernetes.delivery`
EOF
}

variable "worker_sg_id" {
  type = "string"

  description = <<EOF
Security group where additional worker nodes will be joined.
Example:
 * `sg-a7c955cb`
EOF
}

variable "worker_subnet_id" {
  type = "string"

  description = <<EOF
Subnet where additional worker nodes will be joined. Example: `ami-foobar123`.
Example:
 * `subnet-805f57eb`
EOF
}

variable "cluster_tag" {
  type        = "string"
  description = "Tag to enable worker nodes to join the Kube cluster"
}
