terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.29.0"
}

variable "bucket_name" {
  type = "string"
  description = "s3 bucket name"
}

variable "component" {
  type = "string"
  default = "argo"
  description = "name of the component that will be associated with user"
}

data "aws_region" "current" {}

data "aws_s3_bucket" "main" {
  bucket = "${var.bucket_name}"
}

module "user" {
  source = "github.com/agilestacks/terraform-modules.git//iam_user"
  username = "agilestacks-${var.component}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_s3_bucket.main.arn}"
    }
  ]
}
EOF
}

output "access_key_id" {
  value = "${module.user.access_key_id}"
}

output "secret_access_key" {
  value = "${module.user.secret_access_key}"
}
