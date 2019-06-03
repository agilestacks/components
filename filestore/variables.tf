variable "project" {
  type = "string"
}

variable "name" {
  type = "string"
}

variable "zone" {
  type = "string"
}

variable "tier" {
  type = "string"
  default = "STANDARD"
}

variable "share_name" {
  type = "string"
  default = "share1"
}

variable "share_capacity" {
  type = "string"
  default = 1024
}

variable "network" {
  type = "string"
}
