variable "domain_name" {
  type        = "string"
  description = "Domain name associated with R53 hosted zone"
}

variable "namespace" {
  type    = "string"
  default = "harbor"
}

variable "service_prefix" {
  type    = "string"
  default = "svc"
}

variable "nginx_service_name" {
  type = "string"
}
