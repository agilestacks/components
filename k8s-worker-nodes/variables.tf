variable "container_linux_channel" {
  type    = "string"
  default = "stable"

  description = <<EOF
(optional) The Container Linux update channel.

Examples: `stable`, `beta`, `alpha`
EOF
}

variable "container_linux_version_gpu" {
  type = "string"

  default = "1855.4.0"

  description = <<EOF
(optional) The Container Linux version to use for GPU enabled instances from the selected update channel.
For regular instances the latest version from the selected update channel will be used.

Examples: `1465.6.0`
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

variable "autoscaling_group_max_size" {
  type    = "string"
  default = "6"

  description = "The maximum size of the auto scale group."
}

variable "autoscaling_group_min_size" {
  type    = "string"
  default = "0"

  description = "The minimum size of the auto scale group."
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

variable "domain" {
  type        = "string"
  description = "Domain of the stack"
}

variable "pool_name" {
  type = "string"

  description = <<EOF
Name of the pool

Example:
 * `gpu1`
EOF
}

variable "s3_bucket" {
  type = "string"

  description = <<EOF
S3 bucket name to download igniniton config of cluster existing worker nodes from

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
Subnet where additional worker nodes will be joined.
Example:
 * `subnet-805f57eb`
EOF
}

variable "worker_subnet_ids" {
  type    = "string"
  default = ""

  description = <<EOF
Subnets where additional worker nodes will be joined.
This variable overrides worker_subnet_id.
Example:
 * `subnet-805f57eb,subnet-0a0b0c0d,...`
EOF
}

variable "worker_instance_profile" {
  type = "string"

  description = <<EOF
An IAM instance profile to use for worker nodes.
Let use initial worker pool instance profile.
EOF
}

variable "cluster_tag" {
  type        = "string"
  description = "Tag to enable worker nodes to join the Kube cluster"
}
