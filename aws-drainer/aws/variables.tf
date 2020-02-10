variable "domain_name" {
  type = "string"
  description = "Domain name associated with R53 hosted zone"
}

variable "kubeconfig_context" {
  type = "string"
}

variable "namespace" {
  type = "string"
  default = "gitlab"
}

variable "component" {
  type = "string"
  default = "aws-spot-termination-handler"
}