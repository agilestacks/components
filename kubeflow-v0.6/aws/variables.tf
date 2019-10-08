variable "domain_name" {
  type        = "string"
  description = "Domain name associated with R53 hosted zone"
}

variable "namespace" {
  type    = "string"
  default = "istio-system"
}

variable "url_prefix" {
  type = "string"
}

variable "kubeconfig_context" {
  type = "string"
}
