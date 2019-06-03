terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.11.0"
}

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
