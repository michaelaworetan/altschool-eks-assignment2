module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

// Restrictive DB security group allowing access only from within the VPC
resource "aws_security_group" "db" {
  name        = "${var.cluster_name}-db-sg"
  description = "DB access from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  region          = var.aws_region
  vpc_id          = module.vpc.vpc_id
  # Use public subnets to avoid NAT Gateway costs in sandbox
  subnet_ids      = module.vpc.public_subnet_ids
  node_instance_type = var.node_instance_type
  desired_capacity   = var.desired_capacity
  min_size           = var.min_size
  max_size           = var.max_size
  node_group_name    = "${var.cluster_name}-ng"
  cluster_version    = var.cluster_version
}

# Tag public subnets so AWS Load Balancer Controller can discover them for internet-facing ALBs
resource "aws_ec2_tag" "public_subnet_elb_role" {
  count       = length(module.vpc.public_subnet_ids)
  resource_id = module.vpc.public_subnet_ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster" {
  count       = length(module.vpc.public_subnet_ids)
  resource_id = module.vpc.public_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

# Generate secure passwords if not provided via variables
resource "random_password" "postgres" {
  length           = 20
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "mysql" {
  length           = 20
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  db_instance_class      = var.postgres_instance_class
  backup_retention_period = var.postgres_backup_retention_days
  db_name                = var.postgres_db_name
  db_username            = var.postgres_username
  db_password            = coalesce(var.postgres_password, random_password.postgres.result)
  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_ids             = module.vpc.private_subnet_ids
}

module "rds_mysql" {
  source = "../../modules/rds-mysql"

  db_instance_class      = var.mysql_instance_class
  db_backup_retention_period = var.mysql_backup_retention_days
  db_name                = var.mysql_db_name
  db_username            = var.mysql_username
  db_password            = coalesce(var.mysql_password, random_password.mysql.result)
  db_vpc_security_group_ids = [aws_security_group.db.id]
  subnet_ids             = module.vpc.private_subnet_ids
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name = var.dynamodb_table_name
}

module "iam" {
  source = "../../modules/iam"

  iam_user_name = var.developer_user_name
}
