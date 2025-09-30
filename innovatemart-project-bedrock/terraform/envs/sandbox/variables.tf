variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "The name of the EKS cluster and related resources."
  type        = string
  default     = "innovatemart-sandbox"
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "node_instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "t4g.medium"
}

variable "desired_capacity" {
  description = "The desired number of worker nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum number of worker nodes."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "The minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "postgres_instance_class" {
  description = "The instance class for the RDS PostgreSQL database."
  type        = string
  default     = "db.t4g.micro"
}

variable "postgres_backup_retention_days" {
  description = "Automated backup retention in days for Postgres (0 disables backups to reduce cost)."
  type        = number
  default     = 0
}

variable "postgres_db_name" {
  description = "The name of the PostgreSQL database."
  type        = string
  default     = "ordersdb"
}

variable "postgres_username" {
  description = "The username for the PostgreSQL database."
  type        = string
  default     = "orders_user"
}

variable "postgres_password" {
  description = "The password for the PostgreSQL database."
  type        = string
  sensitive   = true
  default     = null
}

variable "mysql_instance_class" {
  description = "The instance class for the RDS MySQL database."
  type        = string
  default     = "db.t4g.micro"
}

variable "mysql_backup_retention_days" {
  description = "Automated backup retention in days for MySQL (0 disables backups to reduce cost)."
  type        = number
  default     = 0
}

variable "mysql_db_name" {
  description = "The name of the MySQL database."
  type        = string
  default     = "catalogdb"
}

variable "mysql_username" {
  description = "The username for the MySQL database."
  type        = string
  default     = "catalog_user"
}

variable "mysql_password" {
  description = "The password for the MySQL database."
  type        = string
  sensitive   = true
  default     = null
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  type        = string
  default     = "carts"
}

variable "developer_user_name" {
  description = "The name of the IAM user for read-only developer access."
  type        = string
  default     = "innovatemart-dev-ro"
}

variable "catalog_database_url" {
  description = "MySQL Database URL for the catalog service (e.g., mysql://user:pass@host:3306/catalog)."
  type        = string
  sensitive   = true
  default     = null
}

variable "orders_database_url" {
  description = "Postgres Database URL for the orders service (e.g., postgres://user:pass@host:5432/orders)."
  type        = string
  sensitive   = true
  default     = null
}


variable "carts_dynamodb_table_name" {
  description = "DynamoDB table name for carts service."
  type        = string
  default     = "carts"
}