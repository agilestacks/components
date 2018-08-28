variable "domain_name" {
  type        = "string"
  description = "Domain name associated with R53 hosted zone"
  default     = "superkube97.voacc76.demo01.kubernetes.delivery"
}

variable "kube_context" {
  description = "describe your variable"
  default     = "superkube97.voacc76.demo01.kubernetes.delivery"
}

variable "namespace" {
  type    = "string"
  default = "harbor"
}

variable "url_prefix" {
  type    = "string"
  default = "harbor.svc"
}

variable "component" {
  type    = "string"
  default = "harbor-harbor-ui"
}
