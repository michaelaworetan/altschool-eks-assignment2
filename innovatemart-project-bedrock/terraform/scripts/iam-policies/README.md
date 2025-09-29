# GitHub Actions Terraform Plan IAM Policy

This folder contains a least-privilege IAM policy that lets the GitHub Actions OIDC role run `terraform plan` successfully, including reading Secrets Manager values used in the plan.

## Files

- `terraform-plan-readonly-policy.json` – Grants read-only access to infrastructure metadata and Secrets Manager values under `retail/*` in `us-east-1`.
  Also allows tagging operations on the specific developer IAM user `innovatemart-dev-ro` used by Terraform, so tag drift can be reconciled safely (`iam:TagUser`, `iam:UntagUser`, `iam:ListUserTags`).

## How to attach to your OIDC role

1. Create the policy:

   - Console: IAM → Policies → Create policy → JSON → paste the file contents → Name e.g. `InnovateMartTerraformPlanReadOnly`
   - Or CLI:

```bash
aws iam create-policy \
  --policy-name InnovateMartTerraformPlanReadOnly \
  --policy-document file://innovatemart-project-bedrock/terraform/scripts/iam/terraform-plan-readonly-policy.json
```

2. Attach policy to your GitHub OIDC role used by Actions (example role name `innovate-mart-github-oidc`):

```bash
ROLE_NAME=innovate-mart-github-oidc
# Prefer customer-managed (Local) to avoid collisions and 'None' outputs
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='InnovateMartTerraformPlanReadOnly'].Arn | [0]" \
  --output text)

# Fallback: build deterministically and validate
if [ -z "$POLICY_ARN" ] || [ "$POLICY_ARN" = "None" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/InnovateMartTerraformPlanReadOnly"
  aws iam get-policy --policy-arn "$POLICY_ARN" --query 'Policy.Arn' --output text >/dev/null
fi

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
echo "Attached $POLICY_ARN to $ROLE_ARN"
```

3. Confirm the trust policy on the role allows your repo and branches/PRs.

4. Re-run the failing plan/apply workflow.

### Updating the policy after edits
If you change `terraform-plan-readonly-policy.json`, create a new policy version and set it as default so GitHub Actions sees the update immediately:

```bash
POLICY_NAME=InnovateMartTerraformPlanReadOnly
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" \
  --output text)

aws iam create-policy-version \
  --policy-arn "$POLICY_ARN" \
  --policy-document file://innovatemart-project-bedrock/terraform/scripts/iam/terraform-plan-readonly-policy.json \
  --set-as-default

aws iam get-policy --policy-arn "$POLICY_ARN" \
  --query 'Policy.DefaultVersionId' --output text
```

## Notes

- The Secrets Manager resource scope is limited to `arn:aws:secretsmanager:us-east-1:474422890464:secret:retail/*`. Adjust the account/region/prefix if you changed them.
- If you add more secret names or regions, update the Resource accordingly.

## Troubleshooting

### Access still denied (explicitDeny)
If `aws iam simulate-principal-policy` shows `explicitDeny` for Secrets Manager reads, a Deny is in effect somewhere. Check:

- Permissions Boundary on the role:

```bash
BOUNDARY_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.PermissionsBoundary.PermissionsBoundaryArn' --output text)
echo "$BOUNDARY_ARN"
if [ "$BOUNDARY_ARN" != "None" ]; then
  VER=$(aws iam get-policy --policy-arn "$BOUNDARY_ARN" --query 'Policy.DefaultVersionId' --output text)
  aws iam get-policy-version --policy-arn "$BOUNDARY_ARN" --version-id "$VER" --query 'PolicyVersion.Document' --output json
fi
```

Ensure the boundary allows:
- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`
- `secretsmanager:GetResourcePolicy`
- `secretsmanager:ListSecretVersionIds`
- `secretsmanager:ListSecrets`
for `arn:aws:secretsmanager:us-east-1:<account>:secret:retail/*`.

- Service Control Policies (SCPs): Org admins should exclude the CI role from any Secrets Manager Deny. In SCPs, Deny always wins.

### zsh globbing in simulations
Quote wildcard ARNs so zsh doesn’t expand `*`:

```zsh
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PRINCIPAL_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
aws iam simulate-principal-policy \
  --policy-source-arn "$PRINCIPAL_ARN" \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns \
    "arn:aws:secretsmanager:us-east-1:${ACCOUNT_ID}:secret:retail/catalog-*" \
    "arn:aws:secretsmanager:us-east-1:${ACCOUNT_ID}:secret:retail/orders-*" \
    "arn:aws:secretsmanager:us-east-1:${ACCOUNT_ID}:secret:retail/carts-*" \
  --query 'EvaluationResults[].{Action:EvalActionName,Resource:EvalResourceName,Decision:EvalDecision}' \
  --output table
```

Tip: If you see AccessDenied for `iam:UntagUser` on `innovatemart-dev-ro`, ensure your policy includes the `AllowManageTagsForDevReadOnlyUser` statement with `iam:TagUser`, `iam:UntagUser`, and `iam:ListUserTags` on the ARN `arn:aws:iam::<account_id>:user/innovatemart-dev-ro`.

### "Secret marked for deletion"
If `get-resource-policy` returns `InvalidRequestException: ... marked for deletion` for `retail/catalog` (or similar), that’s an older base-name secret scheduled for deletion. Terraform often manages suffixed secrets (e.g., `retail/catalog-XYZ123`). Either let the deletion complete or restore the old secret if you need the base name:

```bash
aws secretsmanager restore-secret --secret-id retail/catalog
aws secretsmanager restore-secret --secret-id retail/orders
aws secretsmanager restore-secret --secret-id retail/carts

```
