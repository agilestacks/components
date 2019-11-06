terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "kubernetes" {
  version        = "1.2.0"
}

provider "null" {
  version = "1.0.0"
}

provider "aws" {
  version = "2.14.0"
}

provider "aws" {
  version = "2.14.0"
  alias = "bucket"
  region = "${var.bucket_region}"
}

data "aws_region" "bucket" {
  provider = "aws.bucket"
  current = true
}

variable "endpoints" {
  type    = "map"
  description = "S3 service endpoints by region"
  default = {
    us-east-1 = "s3.amazonaws.com"
    us-east-2 = "s3-us-east-2.amazonaws.com"
    us-west-2 = "s3-us-west-2.amazonaws.com"
    us-west-1 = "s3-us-west-1.amazonaws.com"
    ca-central-1 = "s3-ca-central-1.amazonaws.com"
    eu-west-1 = "s3-eu-west-1.amazonaws.com"
    eu-west-2 = "s3-eu-west-2.amazonaws.com"
    eu-west-3 = "s3-eu-west-3.amazonaws.com"
    eu-central-1 = "s3-eu-central-1.amazonaws.com"
    ap-south-1 = "s3-ap-south-1.amazonaws.com"
    ap-southeast-1 = "s3-ap-southeast-1.amazonaws.com"
    ap-southeast-2 = "s3-ap-southeast-2.amazonaws.com"
    ap-northeast-1 = "s3-ap-northeast-1.amazonaws.com"
    ap-northeast-2 = "s3-ap-northeast-2.amazonaws.com"
    sa-east-1 = "s3-sa-east-1.amazonaws.com"
    us-gov-west-1 = "s3-us-gov-west-1.amazonaws.com"
    cn-north-1 = "s3.cn-north-1.amazonaws.com.cn"
    cn-northwest-1 = "s3.cn-northwest-1.amazonaws.com.cn"
  }
}

variable "bucket_name" {
  type = "string"
  description = "s3 bucket name"
}

variable "bucket_region" {
  type = "string"
  description = "s3 bucket region"
}

variable "component" {
  type = "string"
  default = "argo"
  description = "name of the component that will be associated with user"
}

variable "namespace" {
  type = "string"
  default = "argoproj"
  description = "kubenretes namespace"
}

variable "access_key_ref" {
  type = "string"
  description = "secret reference to access key id"
  default = "accessKey"
}

variable "secret_key_ref" {
  type = "string"
  description = "secret reference to access secret key"
  default = "secretKey"
}

data "aws_s3_bucket" "main" {
  provider = "aws.bucket"
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
        "s3:ListAllMyBuckets",
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl",
        "s3:ListObjects",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_s3_bucket.main.arn}"
    }
  ]
}
EOF
}

resource "kubernetes_secret" "aws" {
  metadata {
    name = "argo-repo-${var.component}"
    namespace = "${var.namespace}"
  }

  data {
    accessKey = "${module.user.access_key_id}"
    secretKey = "${module.user.secret_access_key}"
  }
}

output "secret_name" {
  value = "argo-repo-${var.component}"
}

output "region" {
  value = "${data.aws_region.bucket.name}"
}

output "endpoint" {
  value = "${var.endpoints[ data.aws_region.bucket.name ]}"
}

output "iam_user_name" {
  value = "agilestacks-${var.component}"
}

output "iam_user_arn" {
  value = "${module.user.arn}"
}

output "insecure" {
  value = "false"
}
