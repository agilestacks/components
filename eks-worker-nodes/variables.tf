variable "worker_count" {
  type    = "string"
  default = "1"

  description = <<EOF
The number of worker nodes to be created.
This applies only to cloud platforms.
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

variable "worker_sg_id" {
  type = "string"

  description = <<EOF
Security group where additional worker nodes will be joined.
Example:
 * `sg-a7c955cb`
EOF
}

variable "worker_subnet_ids" {
  type = "string"

  description = <<EOF
Subnets where additional worker nodes will be joined.
Example:
 * `subnet-04dec9a844f678680,subnet-008c4ad928e376b26`
EOF
}

variable "worker_instance_profile" {
  type = "string"
}

variable "cluster_name" {
  type        = "string"
  description = "EKS cluster name"
}
