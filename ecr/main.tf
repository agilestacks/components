terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.17.0"
    }
  }
  required_version = ">= 0.13"
  backend "s3" {}
}

data "aws_caller_identity" "current" {
}

locals {
  default_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": { "AWS": "${data.aws_caller_identity.current.account_id}" },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF

  policy = coalesce(var.policy, local.default_policy)
}

resource "aws_ecr_repository" "main" {
  name = var.name
}

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = local.policy
}

variable "name" {
  type        = string
  description = "Registry name"
  default     = ""
}

variable "policy" {
  type        = string
  description = "Registry IAM policy"
  default     = ""
}

locals {
  url    = aws_ecr_repository.main.repository_url
  region = element(split(".", local.url), 3)
  s      = split("/", local.url)
  host   = element(local.s, 0)
  path   = join("/", slice(local.s, 1, length(local.s)))
}

output "name" {
  value = aws_ecr_repository.main.name
}

output "registry_id" {
  value = aws_ecr_repository.main.registry_id
}

output "image" {
  value = aws_ecr_repository.main.repository_url
}

output "host" {
  value = local.host
}

output "console_url" {
  value = "https://${local.region}.console.aws.amazon.com/ecr/repositories/${local.path}/"
}
