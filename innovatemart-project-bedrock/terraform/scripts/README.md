# EKS aws-auth configuration scripts

This folder contains helper scripts for configuring access to your EKS cluster.

## configure-aws-auth.sh (SSO-friendly)

Grants cluster access to:
- EKS node group role (system:nodes)
- Your read-only developer IAM user `innovatemart-dev-ro` (view-only)
- An admin principal (system:masters) that you specify explicitly

Supports three ways to specify the admin principal:
1) ADMIN_PROFILE (recommended for AWS SSO)
   - The script uses `aws --profile $ADMIN_PROFILE` for all AWS calls
   - It runs `aws sso login` automatically if needed
   - It derives the base IAM role ARN from the SSO session (`assumed-role/...`) and grants that role cluster-admin
2) ADMIN_ROLE_ARN
   - Provide a full IAM role ARN to grant system:masters
3) ADMIN_USER_ARN (not recommended)
   - Provide an IAM user ARN to grant system:masters

Safety guard: The script refuses to grant admin to the read-only user `innovatemart-dev-ro`.

### Usage with AWS SSO

```bash
# Authenticate your SSO profile
aws sso login --profile your-admin-sso

# Run the script, letting it derive the role from SSO
ADMIN_PROFILE=your-admin-sso \
CLUSTER_NAME=innovatemart-sandbox \
REGION=eu-west-1 \
./configure-aws-auth.sh
```

If derivation fails (unusual SSO formats), pass the role ARN explicitly:

```bash
ADMIN_PROFILE=your-admin-sso \
ADMIN_ROLE_ARN=arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_abcdef12 \
CLUSTER_NAME=innovatemart-sandbox \
REGION=eu-west-1 \
./configure-aws-auth.sh
```

### Non-SSO usage

```bash
# Using static creds or a non-SSO profile
export AWS_PROFILE=admin
ADMIN_ROLE_ARN=arn:aws:iam::123456789012:role/cluster-admin \
CLUSTER_NAME=innovatemart-sandbox \
REGION=eu-west-1 \
./configure-aws-auth.sh
```

### Notes
- Override `CLUSTER_NAME` and `REGION` via env vars if your cluster differs.
- The script sets/upgrades your kubeconfig using the chosen profile so kubectl can apply the ConfigMap.
- When running Terraform for the operators stack, export `AWS_PROFILE=your-admin-sso` so kubectl/helm providers can authenticate against the cluster using the same SSO session.
- Read-only user mapping remains unchanged and cannot be elevated by this script.
