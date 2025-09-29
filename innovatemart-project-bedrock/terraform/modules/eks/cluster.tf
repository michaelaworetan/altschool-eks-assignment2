resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Use both API-based IAM authentication and aws-auth ConfigMap
  # Grants the creator admin access by default
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Wait for the EKS control plane to be fully ready
# Prevents race conditions with node groups
resource "time_sleep" "wait_for_cluster" {
  depends_on     = [aws_eks_cluster.this]
  create_duration = "30s"
}

# Fetch the TLS certificate for the cluster's OIDC issuer
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Register the OIDC provider in IAM for IRSA
# Required by controllers like ALB, ExternalDNS, External Secrets, etc.
resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = {
    ManagedBy = "terraform"
    Stack     = var.cluster_name
  }

  depends_on = [time_sleep.wait_for_cluster]
}

# IAM role for the EKS control plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "eks.amazonaws.com" }
        Effect    = "Allow"
      },
    ]
  })
}

# Attach the standard AmazonEKSClusterPolicy to the cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Useful outputs for kubeconfig and IRSA setup
output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IAM Roles for Service Accounts (IRSA)"
  value       = aws_iam_openid_connect_provider.this.arn
}