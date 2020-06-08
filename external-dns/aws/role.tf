terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

resource "aws_iam_role" "role" {
  name               = "external-dns-${element(split(".", var.domain_name), 0)}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "*"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {"superhub.io/stack/${var.domain_name}" = "owned"}
}

resource "aws_iam_role_policy" "policy" {
  name   = "${element(split(".", var.domain_name), 0)}-default"

  role   = aws_iam_role.role.id
  policy = var.policy
}
