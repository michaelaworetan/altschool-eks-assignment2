# resource "aws_eks_cluster_auth" "cluster_auth" {
#   cluster_name = var.cluster_name
# }

# resource "aws_auth" "eks_auth" {
#   cluster_name = var.cluster_name

#   map_roles = [
#     {
#       role_arn = aws_iam_role.eks_cluster_role.arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = ["system:bootstrappers", "system:nodes"]
#     },
#     {
#       role_arn = aws_iam_role.dev_readonly_user.arn
#       username = "dev-readonly-user"
#       groups   = ["system:masters"]
#     }
#   ]
# }