variable "domain_name" {
  type = "string"
}

variable "load_balancer" {
  type = "string"
}

variable "load_balancer_dns_record_type" {
  type = "string"
  default = "CNAME"
}

variable "url_prefix" {
  type = "string"
  default = "auth"
}
