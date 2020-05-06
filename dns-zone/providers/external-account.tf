variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

provider "aws" {
  version    = "2.60.0"
  region     = "eu-west-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
