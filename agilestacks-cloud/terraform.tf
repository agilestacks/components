terraform {
  required_version = ">= 0.9.3"
  backend "s3" {}
}

provider "aws" {}

variable "name" {
  type = "string"
  default = "dev"
}

variable "base_domain" {
  type = "string"
  default = "stacks.delivery"
}


module "ecr" {
  source = "github.com/agilestacks/terraform-modules.git//ecr"
  name   = "agilestacks/${var.name}.${var.base_domain}/cloud"
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
