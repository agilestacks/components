variable "domain_name" {
  type = "string"
  description = "Domain name associated with R53 hosted zone"
}

# variable "namespace" {
#   type = "string"
#   default = "ingress"
# }

variable "url_prefix" {
  type = "string"
}

variable "sso_url_prefix" {
  type = "string"
}

variable "ingress_static_ip" {
  type = "string"
}

variable "ingress_static_host" {
  type = "string"
}
