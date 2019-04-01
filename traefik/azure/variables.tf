variable "domain_name" {
  type        = "string"
  description = "Domain name associated with DNS hosted zone"
}

variable "kubeconfig_context" {
  type = "string"
}

variable "namespace" {
  type    = "string"
  default = "ingress"
}

variable "url_prefix" {
  type = "string"
}

variable "sso_url_prefix" {
  type = "string"
}

variable "auth_url_prefix" {
  type    = "string"
  default = "auth"
}

variable "component" {
  type    = "string"
  default = "traefik"
}

variable "resource_group_name" {
  default = "SuperHub"
}
