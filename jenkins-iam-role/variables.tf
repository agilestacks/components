variable "name" {
  type = "string"
  description = "Logical name of the environment to be able co-exist with other environments under the same AWS account or region"
}

variable "base_domain" {
  type = "string"
  description = "common domain name for the stack"
}
