terraform {
  required_version = ">= 0.9.3"
  backend "s3" {}
}

provider "aws" {}

variable "name" {
  type = "string"
  default = "dev"
}

module "ecr" {
  source = "github.com/agilestacks/terraform-modules//ecr"
  name   = "agilestacks/${var.name}/jenkins"
}

output "repository_url" {
  value = "${module.ecr.repository_url}"
}

output "name" {
  value = "${module.ecr.name}"
}

output "registry_id" {
  value = "${module.ecr.registry_id}"
}