variable "short_name" {
  type = string

  description = <<EOF
Name of the Fargate Profile

Example:
 * `fargate1`
EOF

}

variable "name" {
  type = string

  description = <<EOF
Full name of the Fargate Profile for resource naming

Example:
 * `fargate1-eks-1.dev.superhub.io`
EOF

}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = <<EOF
Private subnets where Fargate Profile will be associated.
Example:
 * `subnet-04dec9a844f678680,subnet-008c4ad928e376b26`
EOF

}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "namespace" {
  type        = string
  default     = ""
  description = "Kubernetes namespace for selecting Pods to execute with this EKS Fargate Profile"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Key-value mapping of Kubernetes labels for selecting Pods to execute with this EKS Fargate Profile"
}
