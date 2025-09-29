resource "aws_iam_policy" "readonly_policy" {
  name        = "readonly-policy"
  description = "Read-only access to EKS resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:ListFargateProfiles",
          "eks:DescribeFargateProfile",
          "eks:ListUpdates",
          "eks:DescribeUpdate",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "dynamodb:ListTables",
          "dynamodb:DescribeTable"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "readonly_policy_attachment" {
  name       = "readonly-policy-attachment"
  policy_arn = aws_iam_policy.readonly_policy.arn
  users      = [var.iam_user_name]
}