provider "aws" {
  alias  = "agilestacks"
}

provider "aws" {
  alias  = "customer"

  # assume_role {
  #   role_arn     = ""  // arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
  #   session_name = "${uuid()}"
  #   external_id  = "${coalesce(var.external_id, aws_caller_identity.current.account_id)}"
  # }
  access_key = "${var.external_aws_access_key}"
  secret_key = "${var.external_aws_secret_key}"
  region         = "${var.external_aws_region}"
}

data "aws_region" "current" {
  current = true
}

data "aws_caller_identity" "agilestacks" {
  provider = "aws.agilestacks"
}

data "aws_caller_identity" "customer" {
  provider = "aws.customer"
}

resource "aws_iam_role" "agilestacks" {
  name_prefix = "agilestacks"
  description = "Role on which behalf AgileStacks Inc will access your cloud account"
  assume_role_policy = <<EOF
{  
  "Version":"2012-10-17",
  "Statement":[  
    {  
      "Effect":"Allow",
      "Principal":{  
        "AWS":"arn:aws:iam::${data.aws_caller_identity.customer.account_id}:root"
      },
      "Action":"sts:AssumeRole",
      "Condition":{  
        "StringEquals":{  
          "sts:ExternalId": "${data.aws_caller_identity.agilestacks.account_id}"
        }
      }
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "agilestacks" {
  name_prefix = "agilestacks"
  role = "${aws_iam_role.agilestacks.id}"
  policy = "${file("policy.json")}"
}