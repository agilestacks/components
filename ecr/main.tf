terraform {
  required_version = ">= 0.12"
  backend "s3" {
  }
}

provider "aws" {
  version = "2.61.0"
}

resource "aws_ecr_repository" "main" {
  name = var.name
}

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = var.policy
}

variable "name" {
  type        = string
  description = "Registry name"
}

variable "policy" {
  type        = string
  description = "Registry IAM policy"
  default     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": "*",
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
