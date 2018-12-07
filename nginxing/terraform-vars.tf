variable "domain_name" {
  type = "string"
  description = "Domain name associated with R53 hosted zone"
}

variable "namespace" {
  type = "string"
  default = "nginx-ingress"
}

variable "url_prefix" {
  type = "string"
}

variable "component" {
  type = "string"
  default = "nginxing"
}