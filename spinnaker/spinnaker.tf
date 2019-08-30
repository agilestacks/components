terraform {
  required_version = ">= 0.11.3"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "spinnaker" {
  name_prefix = "spinnaker-"
  path        = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      }
    },
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

resource "aws_iam_policy" "spinnaker" {
  name = "${aws_iam_role.spinnaker.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iam:GetRole","iam:PassRole"],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "NotAction": ["iam:*", "organizations:*"],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "Action": "organizations:DescribeOrganization",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "spinnaker" {
  name       = "${aws_iam_role.spinnaker.name}"
  policy_arn = "${aws_iam_policy.spinnaker.arn}"
  roles      = ["${aws_iam_role.spinnaker.id}"]
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "role_name" {
  value = "${aws_iam_role.spinnaker.name}"
}

output "role_arn" {
  value = "${aws_iam_role.spinnaker.arn}"
}

output "account_alias" {
  value = "${data.aws_caller_identity.current.account_id}"

  # value = "${coalesce("${data.aws_iam_account_alias.current.account_alias}", "${data.aws_caller_identity.current.account_id}")}"
}
