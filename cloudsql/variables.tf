variable "project" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "name" {
  type = "string"
}

variable "database_version" {
  type = "string"
  default = "POSTGRES_9_6"
}

variable "tier" {
  type = "string"
  default = "db-f1-micro"
}

variable "disk_size" {
  type = "string"
  default = "10"
}

variable "network" {
  type = "string"
}

variable "database_name" {
  type = "string"
}

variable "database_username" {
  type = "string"
}

variable "database_password" {
  type = "string"
}
