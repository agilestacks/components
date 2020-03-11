terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

resource "aws_iam_role" "role" {
  name = "${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = "${var.tags}"
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.name}-policy"
  role        = "${aws_iam_role.role.id}"

  policy = "${var.policy}"
}
