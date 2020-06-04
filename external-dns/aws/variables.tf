variable "domain_name" {
  type        = string
}

variable "name" {
  type        = string
  description = "AWS IAM Role name"
  default     = "external-dns"
}

variable "policy" {
  type        = string
  description = "AWS IAM role policy"

  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
