terraform {
  required_version = ">= 0.11.10"
  backend          "s3"             {}
}

provider "aws" {
  version = "2.14.0"
}

variable "name" {
  type = "string"
}

module "ecr" {
  source = "github.com/agilestacks/terraform-modules.git//ecr"
  name   = "${var.name}"
}

locals {
  region = "${element(split(".", module.ecr.repository_url), 3)}"
  s      = "${split("/", module.ecr.repository_url)}"
  host   = "${element(local.s, 0)}"
  path   = "${join("/", slice(local.s, 1, length(local.s)))}"
}

output "name" {
  value = "${module.ecr.name}"
}

output "host" {
  value = "${local.host}"
}

output "image" {
  value = "${module.ecr.repository_url}"
}

output "console_url" {
  value = "https://${local.region}.console.aws.amazon.com/ecr/repositories/${local.path}/"
}
