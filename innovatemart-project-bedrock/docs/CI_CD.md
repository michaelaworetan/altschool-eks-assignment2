# CI/CD: GitHub Actions + AWS OIDC

Docs index: [Architecture](./ARCHITECTURE.md) | [Deployment Guide](./DEPLOYMENT_GUIDE.md) | [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) | [CI/CD](./CI_CD.md) | [Cost Notes](./COST_NOTES.md) | [Back to root README](../../README.md)

This document explains how the pipelines work, what they require, and how to troubleshoot them.

## Overview

- Source control: GitHub
- Pipelines: GitHub Actions
- Cloud auth: AWS OIDC (the workflow exchanges a short-lived token to assume an AWS IAM role)

Workflows:
- `.github/workflows/terraform-plan.yml` – Plan on feature branches and PRs to `main` when Terraform files change.
- `.github/workflows/terraform-apply.yml` – Apply on push to `main`; also deploy k8s if Terraform or k8s manifests changed.

## Workflow behavior

1. Detect changes
   - Uses `dorny/paths-filter` to decide whether to run Terraform and/or k8s deploy.
2. Sandbox → Operators
   - Sandbox (VPC, EKS, RDS, DynamoDB, IAM) runs first.
   - Operators (ALB controller, ExternalDNS, ESO, IRSA) runs second.
3. Deploy
  - Applies Kubernetes manifests with `../scripts/deploy-app.sh`.
   - The script generates kubeconfig, applies ExternalSecrets, then the app overlay (`k8s/overlays/sandbox`).

## Required configuration

- GitHub repository settings:
  - Actions secret `AWS_ROLE_TO_ASSUME`: The AWS IAM role ARN the workflow assumes.
  - Actions variable `AWS_REGION`: e.g., `us-east-1`.
- AWS IAM:
  - OIDC trust on the role to allow GitHub to assume it.
  - Attach the least-privilege policy: `../terraform/scripts/iam/terraform-plan-readonly-policy.json`.
  - After policy edits, create a new policy version and set it as default.

## First-run EKS access

The IAM role used by Actions must have access to your EKS cluster, otherwise the Kubernetes provider in the operators stack will fail with `Unauthorized`.

Run once (from an admin session):

```bash
../terraform/scripts/create-eks-access-entry.sh \
  -c innovatemart-sandbox \
  -r us-east-1 \
  -a arn:aws:iam::<account-id>:role/innovate-mart-github-oidc
```

This associates `AmazonEKSClusterAdminPolicy` at cluster scope to the role.

## Least-privilege policy (high level)

- Read-only describes for EKS/EC2/IAM/RDS/DynamoDB/CloudWatch/Route53/ACM.
- Secrets Manager read for `arn:aws:secretsmanager:us-east-1:<account-id>:secret:retail/*`.
- ACM `ListTagsForCertificate` for certificate tag reads.
- IAM Tag/Untag/ListUserTags for the specific dev read-only user (to reconcile tag drift), or ignore tags via Terraform lifecycle if preferred.

File: `../terraform/scripts/iam/terraform-plan-readonly-policy.json`

## Troubleshooting

- `Unauthorized` on Kubernetes resources in operators
  - Ensure the EKS access entry exists for the Actions role (script above).
  - Confirm your workflow uses the correct region (`AWS_REGION`).

- `AccessDenied` on Secrets Manager GetSecretValue
  - Ensure the policy default version includes `secretsmanager:GetSecretValue` and is scoped to your `retail/*` secrets.
  - Confirm region is `us-east-1` if your policy includes a region guard.

- `AccessDenied` on ACM ListTagsForCertificate
  - Ensure the policy includes `acm:ListTagsForCertificate` (either `Resource: *` or `arn:aws:acm:us-east-1:<account-id>:certificate/*`).

- Drift due to ALB controller replicas
  - The operators Helm chart sets replicas=1. The deploy script scales it to 0 for a single-node sandbox. This is intentional to free pod slots.

- Plan runs but Apply doesn’t
  - The apply job only runs when Terraform paths changed. The deploy job runs when Terraform or k8s paths changed. Check the detect job outputs.

## Security notes

- No long-lived AWS keys are stored in GitHub.
- The assumed role should be scoped to the minimum required permissions.
- Consider using AWS IAM Access Analyzer policy validation and the IAM policy simulator when tightening permissions.

See also: [Deployment Guide](./DEPLOYMENT_GUIDE.md) · [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) · [Cost Notes](./COST_NOTES.md)
