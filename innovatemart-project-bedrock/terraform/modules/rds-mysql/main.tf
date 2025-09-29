resource "aws_db_subnet_group" "mysql" {
  name       = "mysql-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql_instance" {
  identifier               = "catalog-mysql"
  engine                   = "mysql"
  engine_version           = var.db_engine_version
  instance_class           = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  storage_type             = var.db_storage_type
  backup_retention_period  = var.db_backup_retention_period
  username                 = var.db_username
  password                 = var.db_password
  db_name                  = var.db_name
  port                     = 3306
  multi_az                 = false
  publicly_accessible      = false
  skip_final_snapshot      = true
  vpc_security_group_ids   = var.db_vpc_security_group_ids
  db_subnet_group_name     = aws_db_subnet_group.mysql.name

  tags = {
    Name = "catalog-mysql"
  }
}