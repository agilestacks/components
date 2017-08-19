variable "external_id" {
  type = "string"
  description = "External ID to assume role"
  default = ""
}

variable "assume_role_arn" {
  type = "string"
  description = "arn of the role to assume"
  default = ""
}

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
