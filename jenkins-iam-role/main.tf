terraform {
  required_version = ">= 0.9.3"
  backend "s3" {}
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "jenkins" {
  name = "${var.name}.${var.base_domain}-jenkins_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.worker_role}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins" {
  name = "jenkins_iam_role_policy"
  role = "${aws_iam_role.jenkins.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
