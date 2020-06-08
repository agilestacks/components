variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

provider "aws" {
  version    = "2.61.0"
  region     = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
