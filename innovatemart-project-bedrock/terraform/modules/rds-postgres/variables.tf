variable "db_instance_class" {
  description = "The instance type of the RDS PostgreSQL database."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "db_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  description = "The allocated storage size for the database (in GB)."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "The number of days to retain automated backups (0 disables automated backups to minimize cost)."
  type        = number
  default     = 0
}

variable "vpc_security_group_ids" {
  description = "The VPC security group IDs to associate with the RDS instance."
  type        = list(string)
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}