resource "aws_eks_node_group" "default" {
  cluster_name    = var.cluster_name
  node_group_name = coalesce(var.node_group_name, "${var.cluster_name}-node-group")
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_ARM_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  tags = {
    Name = coalesce(var.node_group_name, "${var.cluster_name}-node-group")
  }

  # Ensure the EKS cluster and required IAM policy attachments exist before creating the node group
  depends_on = [
    time_sleep.wait_for_cluster,
    aws_iam_role_policy_attachment.node_group_policy_attachment,
    aws_iam_role_policy_attachment.cni_policy_attachment,
    aws_iam_role_policy_attachment.ecr_policy_attachment,
  ]
}

resource "aws_iam_role" "node_group_role" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}