terraform {
  required_version = ">= 0.12"
  backend "s3" {}
}

provider "aws" {
  version = "2.49.0"
}

locals {
  name1 = replace(var.name, ".", "-")
  name2 = substr(local.name1, 0, min(length(local.name1), 50))
}

data "aws_eks_cluster" "target" {
  name = var.cluster_name
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_eks_cluster.target.vpc_config[0].vpc_id

  tags = {
    kind = "private"
  }
}

resource "aws_iam_role" "fargate" {
  name = "eks-fargate-${local.name2}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

# https://www.terraform.io/docs/providers/aws/r/eks_fargate_profile.html
# https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateFargateProfile.html
# https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html
# At this time, pods running on Fargate are not assigned public IP addresses, so only
# private subnets (with no direct route to an Internet Gateway) are accepted for this parameter.
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = data.aws_eks_cluster.target.name
  fargate_profile_name   = var.short_name
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = coalescelist(var.subnet_ids, tolist(data.aws_subnet_ids.private.ids))

  # up to five selectors in a Fargate profile
  selector {
    namespace = var.namespace
    labels    = var.labels
  }
}
