terraform {
  required_version = ">= 0.9.3"
  backend "s3" {}
}

provider "aws" {}

variable "name" {
  type = "string"
}

module "ecr" {
  source = "github.com/agilestacks/terraform-modules.git//ecr"
  name   = "${var.name}"
}

output "repository_url" {
  value = "${coalesce("${module.ecr.repository_url}", "** unset **")}"
}

output "name" {
  value = "${module.ecr.name}"
}

output "registry_id" {
  value = "${module.ecr.registry_id}"
}
