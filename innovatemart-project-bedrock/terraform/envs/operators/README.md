# Operators stack

Installs cluster add-ons (ALB Controller, ExternalDNS, External Secrets) and configures IRSA roles. Uses an S3 backend for state.

For CI/CD pipeline details (Plan/Apply and deploy order), see `../../docs/CI_CD.md`.

## Backend (S3) configuration

Default backend is defined in `backend.tf`:
- bucket: `innovatemart-terraform-state`
- key: `operators/terraform.tfstate`
- region: `eu-west-1`
- dynamodb_table: `terraform-locks`

<!-- Override with a backend.hcl (copy from `backend.hcl.example`):

```hcl
# backend.hcl
bucket         = "innovatemart-terraform-state"
key            = "operators/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-locks"
encrypt        = true
# Optional: pin the AWS profile (SSO or static). Usually it's better to set AWS_PROFILE in the shell.
# profile        = "your-admin-sso" -->
```

Initialize with overrides:

```bash
terraform init -upgrade -backend-config=backend.hcl
```

If the bucket/table do not exist, bootstrap them first:

```bash
cd ../../../state-bootstrap
terraform init
terraform apply -auto-approve \
  -var aws_region=eu-west-1 \
  -var state_bucket_name=innovatemart-terraform-state \
  -var lock_table_name=terraform-locks
cd -
```

## Using AWS SSO

```bash
# Authenticate your SSO profile
aws sso login --profile your-admin-sso

# Ensure Terraform uses that profile
export AWS_PROFILE=your-admin-sso

# Initialize/apply
terraform init -upgrade
terraform apply
```

If init still fails with 403 Forbidden:
- Verify you are in the correct AWS account and region
- Verify the bucket exists and is in the region you configured
- Ensure your profile has permissions to read/write the bucket and to use DynamoDB table

Quick checks:

```bash
aws --profile your-admin-sso sts get-caller-identity
aws --profile your-admin-sso s3api head-bucket --bucket innovatemart-terraform-state
aws --profile your-admin-sso s3api get-bucket-location --bucket innovatemart-terraform-state
```

If the bucket is in a different region, set that region in `backend.hcl` and re-run `terraform init -reconfigure`.

## Dependency on sandbox state

This stack reads outputs from the sandbox stack via remote state. Make sure the sandbox env is applied first and its state is accessible in the same S3 bucket/region.

See also `../../scripts/README.md` for SSO-friendly aws-auth configuration.

### Overriding sandbox remote state auth/region

If you used a different AWS account/profile or region for the sandbox state, you can point this stack to the right location/auth without editing code:

```
export AWS_PROFILE=your-admin-sso
terraform plan \
  -var sandbox_state_bucket=innovatemart-terraform-state \
  -var sandbox_state_key=sandbox/terraform.tfstate \
  -var sandbox_state_region=eu-west-1 \
  -var sandbox_state_profile=your-admin-sso
```

You can also supply a `sandbox_state_role_arn` if you need to assume a role to read the sandbox state.
