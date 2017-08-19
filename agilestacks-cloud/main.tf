provider "aws" {
  alias  = "agilestacks"
}

provider "aws" {
  alias  = "client"

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

data "aws_caller_identity" "client" {
  provider = "aws.client"
}

resource "aws_iam_role" "agilestacks" {
  provider = "aws.client"

  name_prefix = "agilestacks"
  description = "Role on which behalf AgileStacks Inc will access your cloud account"
  assume_role_policy = <<EOF
{  
  "Version":"2012-10-17",
  "Statement":[  
    {  
      "Effect":"Allow",
      "Principal":{  
        "AWS":"arn:aws:iam::${data.aws_caller_identity.client.account_id}:root"
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
  provider = "aws.client"

  name_prefix = "agilestacks"
  role = "${aws_iam_role.agilestacks.id}"
  policy = "${file("policy.json")}"
}

resource "random_pet" "any" {
  prefix = "asi"
  separator = "-"
}

resource "aws_s3_bucket" "main" {
  provider = "aws.client"

  bucket = "${random_pet.any.id}.${var.name}.${var.base_domain}"

  acl = "private"

  force_destroy = true

  versioning {
      enabled = true
  }

  tags {
      Provider = "AgileStacks Inc"
      Pupose   = "For intermediate storage of automation scripts"
  }

  lifecycle_rule {
    prefix  = "/"
    enabled = true
    abort_incomplete_multipart_upload_days = 1

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 90
    }
  }
}

data "aws_route53_zone" "base" {
  provider     = "aws.agilestacks"
  name         = "${var.base_domain}"
  private_zone = false
}

resource "aws_route53_zone" "new" {
  provider = "aws.client"
  name     = "${var.name}.${var.base_domain}"
  comment  = "Base domain for all stacks associated to this cloud account"
  tags {
      Provider  = "AgileStacks Inc"
      Pupose    = "Base domain for all stacks associated to this cloud account"
  }
  force_destroy = true
}

resource "aws_route53_record" "new" {
  provider = "aws.agilestacks"
  zone_id  = "${data.aws_route53_zone.base.zone_id}"
  name     = "${var.name}.${var.base_domain}"
  type     = "NS"
  ttl      = "30"
  records = [
    "${aws_route53_zone.new.name_servers.0}",
    "${aws_route53_zone.new.name_servers.1}",
    "${aws_route53_zone.new.name_servers.2}",
    "${aws_route53_zone.new.name_servers.3}",
  ]
}