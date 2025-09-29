variable "db_username" {
  description = "The username for the MySQL database."
  type        = string
}

variable "db_password" {
  description = "The password for the MySQL database."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "The name of the MySQL database."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the MySQL RDS instance."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage (in GiB) for the MySQL RDS instance."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "The version of the MySQL database engine."
  type        = string
  default     = "8.0"
}

variable "db_multi_az" {
  description = "Whether to create a Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "db_storage_type" {
  description = "The storage type for the MySQL RDS instance."
  type        = string
  default     = "gp3"
}

variable "db_backup_retention_period" {
  description = "The number of days to retain automated backups (0 disables automated backups to minimize cost)."
  type        = number
  default     = 0
}

variable "db_vpc_security_group_ids" {
  description = "The VPC security group IDs to associate with the MySQL RDS instance."
  type        = list(string)
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}