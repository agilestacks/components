variable "client_aws_region" {
  type = "string"
  description = "External account region"
  default = "us-east-2"
}

variable "base_domain" {
  type = "string"
  description = "Cloud account base domain name"
}

variable "name" {
  type = "string"
  description = "Cloud account name that will be used as DNS prefix"
}
