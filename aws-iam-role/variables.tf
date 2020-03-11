variable "name" {
  type        = "string"
  description = "AWS IAM Role name"
}

variable "tags" {
  type        = "map"
  description = "AWS IAM Role tags"
}

variable "policy" {
  type        = "string"
  description = "AWS IAM role policy"
}
