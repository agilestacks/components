variable "domain_name" {
  type = "string"
  description = "Domain name associated with R53 hosted zone"
}

variable "namespace" {
  type = "string"
  default = "ingress"
}

variable "url_prefix" {
  type = "string"
}

variable "sso_url_prefix" {
  type = "string"
}

variable "auth_url_prefix" {
  type = "string"
  default = "auth"
}

variable "component" {
  type = "string"
  default = "traefik"
}