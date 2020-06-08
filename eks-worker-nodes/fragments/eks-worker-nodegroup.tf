data "aws_iam_role" "node" {
  name = var.role
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = var.cluster_name
  node_group_name = var.short_name
  node_role_arn   = data.aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.pool_count
    min_size     = var.pool_count
    max_size     = max(var.pool_max_count, var.pool_count)
  }

  ami_type       = "AL2_x86_64${local.instance_gpu ? "_GPU" : ""}"
  disk_size      = var.root_volume_size
  instance_types = [var.instance_type]

  remote_access {
    ec2_ssh_key = var.keypair
  }

  tags = {
    Name = "eks-nodegroup-${var.short_name}-${var.cluster_name}"
  }
}
