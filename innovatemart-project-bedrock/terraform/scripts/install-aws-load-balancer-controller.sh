#!/usr/bin/env bash
set -euo pipefail

# Installs AWS Load Balancer Controller (ALB controller) with IRSA on an EKS cluster.
#
# Requirements:
# - aws, kubectl, helm, curl available in PATH
# - EKS cluster has IAM OIDC provider associated (via eksctl or console)
#
# Usage:
#   ./install-aws-load-balancer-controller.sh [CLUSTER_NAME] [REGION]
#   or set env vars: CLUSTER_NAME, REGION
#

CLUSTER_NAME=${1:-${CLUSTER_NAME:-innovatemart-sandbox}}
REGION=${2:-${REGION:-eu-west-1}}

echo "Cluster: $CLUSTER_NAME | Region: $REGION"

command -v aws >/dev/null 2>&1 || { echo "aws CLI is required" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_ISSUER=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.identity.oidc.issuer' --output text)
if [[ -z "$OIDC_ISSUER" || "$OIDC_ISSUER" == "None" ]]; then
  echo "ERROR: Cluster has no OIDC issuer configured." >&2
  echo "Please associate OIDC provider (one-time):" >&2
  echo "  eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $REGION --approve" >&2
  exit 1
fi

OIDC_PROVIDER=${OIDC_ISSUER#https://}
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
echo "OIDC issuer: $OIDC_ISSUER"
echo "OIDC provider ARN: $OIDC_PROVIDER_ARN"

# Validate OIDC provider exists in IAM
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" >/dev/null 2>&1; then
  echo "ERROR: IAM OIDC provider not found for $OIDC_PROVIDER_ARN" >&2
  echo "Create it (recommended via eksctl):" >&2
  echo "  eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $REGION --approve" >&2
  exit 1
fi

# Create policy for ALB controller if not exists
POLICY_NAME="${CLUSTER_NAME}-AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" --output text)
if [[ "$POLICY_ARN" == "None" || -z "$POLICY_ARN" ]]; then
  TMP_POLICY=$(mktemp)
  # Fetch official policy from the AWS Load Balancer Controller repo
  curl -fsSL https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json -o "$TMP_POLICY"
  echo "Creating IAM policy $POLICY_NAME"
  POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://"$TMP_POLICY" --query Policy.Arn --output text)
  rm -f "$TMP_POLICY"
else
  echo "Using existing policy: $POLICY_ARN"
fi

# Create role for service account with trust relationship to OIDC provider
ROLE_NAME="${CLUSTER_NAME}-alb-controller-role"
ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName=='${ROLE_NAME}'].Arn | [0]" --output text)
if [[ "$ROLE_ARN" == "None" || -z "$ROLE_ARN" ]]; then
  TMP_TRUST=$(mktemp)
  cat > "$TMP_TRUST" <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "${OIDC_PROVIDER_ARN}" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
JSON
  echo "Creating IAM role $ROLE_NAME"
  ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://"$TMP_TRUST" --query Role.Arn --output text)
  rm -f "$TMP_TRUST"
else
  echo "Using existing role: $ROLE_ARN"
fi

# Attach policy to role (idempotent)
if ! aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'] | length(@)" --output text | grep -q '^1$'; then
  echo "Attaching policy to role"
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
fi

# Ensure kube-system namespace exists and that we have context
kubectl get ns kube-system >/dev/null

# Install/upgrade chart
helm repo add eks https://aws.github.io/eks-charts >/dev/null
helm repo update >/dev/null

echo "Installing/Upgrading AWS Load Balancer Controller via Helm..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$REGION" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"="$ROLE_ARN"

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=5m

echo "AWS Load Balancer Controller is installed and ready."