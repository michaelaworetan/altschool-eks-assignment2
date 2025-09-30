output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "secretsmanager_catalog_arn" {
  value       = aws_secretsmanager_secret.catalog.arn
  description = "Secrets Manager ARN for retail/catalog"
}

output "secretsmanager_orders_arn" {
  value       = aws_secretsmanager_secret.orders.arn
  description = "Secrets Manager ARN for retail/orders"
}

output "secretsmanager_carts_arn" {
  value       = aws_secretsmanager_secret.carts.arn
  description = "Secrets Manager ARN for retail/carts"
}

output "aws_region" {
  description = "AWS region used by the sandbox environment"
  value       = var.aws_region
}

output "rds_postgres_endpoint" {
  value = module.rds_postgres.endpoint
}

output "rds_mysql_endpoint" {
  value = module.rds_mysql.endpoint
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

# IAM user outputs for developer read-only access
output "iam_user_name" {
  value = module.iam.iam_user_name
}

output "iam_user_arn" {
  value = module.iam.iam_user_arn
}

output "iam_user_access_key_id" {
  value = module.iam.iam_user_access_key_id
}

output "iam_user_secret_access_key" {
  value     = module.iam.iam_user_secret_access_key
  sensitive = true
}
