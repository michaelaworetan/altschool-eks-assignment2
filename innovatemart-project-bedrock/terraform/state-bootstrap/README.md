# Terraform Remote State Setup

This directory sets up the S3 bucket and DynamoDB table required for managing Terraform remote state.

## Overview

The setup includes:

- **S3 Bucket**: Stores the Terraform state file securely.

  - Versioning enabled
  - Server-side encryption (AES256)

- **DynamoDB Table**: Provides state locking and consistency to prevent concurrent 
   modifications.
  - Pay-per-request billing
  - Hash key: `LockID`

## Configuration

The bootstrap uses these default values (from `variables.tf`):

- **S3 Bucket**: `innovatemart-terraform-state-eu-west-1-ma2025`
- **DynamoDB Table**: `innovatemart-terraform-locks`
- **Region**: `eu-west-1`

## Usage

```bash
# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Important Notes

- Run this **before** deploying main infrastructure
- The S3 bucket name must be globally unique
- Don't delete these resources while other Terraform configurations depend on them