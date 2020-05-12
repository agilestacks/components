variable "linux_channel" {
  type    = string
  default = "stable"
}

variable "linux_distro" {
  type    = string
  default = "flatcar"
}


variable "ubuntu_version" {
  type    = string
  description = "Ubuntu version used for worker"
}


variable "linux_gpu_version" {
  type        = string
  default     = "1855.4.0"
  description = "Image version that used"
}

variable "linux_version" {
  type        = string
  default     = "*"
  description = <<EOF
Specifies version constraint for CoreOS image. If empty then it will lead to:
- GPU instance will default to 1465.6.0
- Non cpu instance will default to latest
EOF

}

variable "keypair" {
  type        = string
  default     = "agilestacks"
  description = "Name of an SSH key located within the AWS region. Example: coreos-user."
}

variable "instance_size" {
  type        = list(string)
  default     = []
  description = "Instnace size list"
}

variable "spot_allocation_strategy" {
  type        = string
  default     = "capacity-optimized"
  description = "Mixed ASG allocation strategy"
}

variable "on_demand_base_capacity" {
  type        = string
  default     = "0"
  description = "On-demand instance count in mixed ASG"
}

variable "ec2_ami_override" {
  type        = string
  default     = ""
  description = "(optional) AMI override for all nodes. Example: `ami-foobar123`."
}

variable "autoscaling_enabled" {
  type        = bool
  default     = false
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
  default     = "30"
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

variable "name" {
  type = string

  description = <<EOF
Name of the pool

Example:
 * `gpu1`
EOF

}

variable "s3_bucket" {
  type = string

  description = <<EOF
S3 bucket name to download igniniton config of
cluster existing worker nodes from
EOF

}

variable "s3_bucket_region" {
  type        = string
  default     = "us-east-1"
  description = "Region of s3 bucket (default: us-east-1)"
}

variable "bootstrap_script_key" {
  type        = string
  default     = ""
  description = <<EOF
Path in s3 bucket to ignition key
If empty (backward compatibility) then
default location from stack-k8s-aws
<DOMAIN_NAME>/stack-k8s-aws/ignition/ignition_worker.json
EOF

}

variable "sg_ids" {
  type        = list(string)
  default     = []
  description = "Security group ids"
}

variable "subnet_ids" {
  type    = list(string)
  default = []

  description = "Subnets where additional worker nodes will be joined."
}

variable "instance_profile" {
  type = string

  description = <<EOF
An IAM instance profile to use for worker nodes.
Let use initial worker pool instance profile.
EOF

}

variable "cluster_tag" {
  type        = string
  description = "Tag to enable worker nodes to join the Kube cluster"
}

variable "virtualization_type" {
  type        = string
  default     = "hvm"
  description = "Worker pool ec2 instance vrtualization type (default: hvm)"
}

variable "domain_name" {
  type        = string
  description = "Domain name of the cluster that for worker pool"
}

variable "service_dns_ip" {
  default     = ""
  description = "Optional. ip address of cluster dns"
}

variable "cloud_init_config_boot_s3" {
  type        = string
  description = "Cloud init boot config location"
}
