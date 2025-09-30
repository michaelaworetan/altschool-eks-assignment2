resource "aws_secretsmanager_secret" "catalog" {
  name        = "retail/catalog"
  description = "Catalog service database URL"
}

locals {
  catalog_endpoint_hostport = module.rds_mysql.endpoint # e.g., host:3306
  orders_endpoint_hostport  = module.rds_postgres.endpoint # e.g., host:5432
  catalog_effective_password = coalesce(var.mysql_password, try(random_password.mysql.result, null), "")
  orders_effective_password  = coalesce(var.postgres_password, try(random_password.postgres.result, null), "")
  catalog_db_url_auto       = "mysql://${var.mysql_username}:${local.catalog_effective_password}@${local.catalog_endpoint_hostport}/${var.mysql_db_name}"
  # Provide both formats for orders: the app commonly expects DATABASE_URL as postgres://...
  # and Spring Boot will honor SPRING_DATASOURCE_URL when provided.
  orders_db_url_auto        = "postgres://${var.postgres_username}:${local.orders_effective_password}@${local.orders_endpoint_hostport}/${var.postgres_db_name}"
  orders_jdbc_url_auto      = "jdbc:postgresql://${local.orders_endpoint_hostport}/${var.postgres_db_name}?user=${var.postgres_username}&password=${local.orders_effective_password}"
}

resource "aws_secretsmanager_secret_version" "catalog" {
  secret_id     = aws_secretsmanager_secret.catalog.id
  secret_string = jsonencode({
    "database-url" = coalesce(var.catalog_database_url, local.catalog_db_url_auto)
  })
}

resource "aws_secretsmanager_secret" "orders" {
  name        = "retail/orders"
  description = "Orders service database URL"
}

resource "aws_secretsmanager_secret_version" "orders" {
  secret_id     = aws_secretsmanager_secret.orders.id
  secret_string = jsonencode({
    "database-url" = coalesce(var.orders_database_url, local.orders_db_url_auto)
    # Extra key to support Spring's SPRING_DATASOURCE_URL explicitly
    "spring-datasource-url" = local.orders_jdbc_url_auto
  })
}

resource "aws_secretsmanager_secret" "carts" {
  name        = "retail/carts"
  description = "Carts service DynamoDB configuration"
}

resource "aws_secretsmanager_secret_version" "carts" {
  secret_id     = aws_secretsmanager_secret.carts.id
  secret_string = jsonencode({
    DYNAMODB_TABLE_NAME = var.carts_dynamodb_table_name
  })
}