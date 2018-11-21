variable "name" {
  type = "string"
  description = "Google DNS managed zone name"
}

variable "domain_name" {
  type = "string"
  description = "Domain name associated with Google DNS managed zone"
}

variable "kubeconfig_context" {
  type = "string"
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
