resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "postgres-subnet-group"
  }
}

resource "aws_db_instance" "postgres_instance" {
  identifier               = "orders-postgres"
  engine                   = "postgres"
  instance_class           = var.db_instance_class
  allocated_storage        = var.allocated_storage
  backup_retention_period  = var.backup_retention_period
  username                 = var.db_username
  password                 = var.db_password
  db_name                  = var.db_name
  port                     = 5432
  multi_az                 = false
  publicly_accessible      = false
  skip_final_snapshot      = true
  vpc_security_group_ids   = var.vpc_security_group_ids
  db_subnet_group_name     = aws_db_subnet_group.postgres.name
  storage_type             = "gp3"

  tags = {
    Name = "orders-postgres"
  }
}