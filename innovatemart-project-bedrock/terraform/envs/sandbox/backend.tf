terraform {
  backend "s3" {
    bucket         = "innovatemart-terraform-state-eu-west-1-ma2025"
    key            = "sandbox/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "innovatemart-terraform-locks"
    encrypt        = true
  }
}