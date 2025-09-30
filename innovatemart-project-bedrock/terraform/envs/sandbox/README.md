# Sandbox stack

Provisions VPC, EKS, RDS, DynamoDB, IAM, and Secrets Manager. Uses an S3 backend for state.

## Backend (S3) configuration

Default backend is defined in `backend.tf`:
- bucket: `innovatemart-terraform-state`
- key: `sandbox/terraform.tfstate`
- region: `eu-west-1`
- dynamodb_table: `terraform-locks`


Initialize with overrides:

```bash
terraform init -upgrade
```
<!-- ```bash
terraform init -upgrade -backend-config=backend.hcl
``` -->

If the bucket/table do not exist, bootstrap them first (in `../../state-bootstrap`):

```bash
cd ../../state-bootstrap
terraform init
terraform apply -auto-approve \
  -var aws_region=eu-west-1 \
  -var state_bucket_name=innovatemart-terraform-state \
  -var lock_table_name=terraform-locks
cd -
```

## Using AWS SSO

```bash
aws sso login --profile your-admin-sso
export AWS_PROFILE=your-admin-sso
terraform init -upgrade
terraform apply
```

If init fails with 403 Forbidden:
- Wrong account or region
- Missing permissions to S3/DynamoDB
- Bucket exists in a different region than configured

Checks:

```bash
aws --profile your-admin-sso sts get-caller-identity
aws --profile your-admin-sso s3api head-bucket --bucket innovatemart-terraform-state
aws --profile your-admin-sso s3api get-bucket-location --bucket innovatemart-terraform-state
```

<!-- If region differs, set the correct `region` in `backend.hcl` and run `terraform init -reconfigure`. -->
If region differs, set the correct `region` and run `terraform init -reconfigure`.

## Next: Apply the operators stack

Once the sandbox stack has been applied successfully, apply the operators stack to install cluster add-ons (ALB controller, ExternalDNS, External Secrets) and IRSA bindings:

```bash
cd ../operators
terraform init
terraform plan
terraform apply
```

This stack reads outputs from the sandbox remote state; ensure the sandbox state bucket/key/region are accessible. See `terraform/envs/operators/README.md` for details.
