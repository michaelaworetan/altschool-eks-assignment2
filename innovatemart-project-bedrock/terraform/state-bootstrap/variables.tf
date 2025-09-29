variable "aws_region" {
  description = "AWS region for the bootstrap resources"
  type        = string
  default     = "eu-west-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket to store Terraform remote state"
  type        = string
  default     = "innovatemart-terraform-state-eu-west-1-ma2025"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "innovatemart-terraform-locks"
}
