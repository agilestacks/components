variable "keypair" {
  type        = string
  default     = "agilestacks"
  description = "Name of an SSH key located within the AWS region. Example: coreos-user."
}

variable "instance_type" {
  type        = string
  default     = "r5.large"
  description = "Instance size for the worker node(s). Example: `t2.small`."
}

variable "spot_price" {
  type        = string
  default     = "0.06"
  description = "Spot request price. Empty for on-demand"
}

variable "autoscaling_enabled" {
  type        = string
  default     = "false"
  description = "Enable autoscaling by adding special auto scale group tags"
}

variable "pool_max_count" {
  type        = string
  default     = "1"
  description = "The maximum size of the auto scale group."
}

variable "pool_count" {
  type        = string
  default     = "1"
  description = "The minimum size of the auto scale group."
}

variable "root_volume_type" {
  type        = string
  default     = "gp2"
  description = "The type of volume for the root block device of worker nodes."
}

variable "root_volume_size" {
  type        = string
  default     = "50"
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
}

variable "root_volume_iops" {
  type    = string
  default = "100"

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF

}

variable "load_balancers" {
  type    = list(string)
  default = []

  description = <<EOF
(optional) List of ELBs to attach all worker instances to.
This is useful for exposing NodePort services via load-balancers managed separately from the cluster.

Example:
 * `["ingress-nginx"]`
EOF

}

variable "short_name" {
  type = string

  description = <<EOF
Short name of the pool

Example:
 * `gpu1`
EOF

}

variable "name" {
  type = string

  description = <<EOF
Full name of the pool

Example:
 * `gpu1-eks-1.dev.superhub.io`
EOF

}

variable "sg_ids" {
  type        = list(string)
  default     = []
  description = <<EOF
Security group where additional worker nodes will be joined.
Example:
 * `sg-a7c955cb`
EOF

}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = <<EOF
Subnets where additional worker nodes will be joined.
Example:
 * `subnet-04dec9a844f678680,subnet-008c4ad928e376b26`
EOF

}

variable "instance_profile" {
  type        = string
  description = "Worker instance profile"
}

variable "role" {
  type        = string
  description = "Worker IAM role"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

# AWS defaults below
# https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#mixed_instances_policy-instances_distribution
# https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_InstancesDistribution.html
variable "on_demand_base_capacity" {
  type    = string
  default = "0"
}

variable "on_demand_percentage_above_base_capacity" {
  type    = string
  default = "0" # the default is 100, yet we want spot instances thus 0
}

variable "spot_allocation_strategy" {
  type    = string
  default = "capacity-optimized"
}

variable "spot_instance_pools" {
  type    = string
  default = "2"
}
