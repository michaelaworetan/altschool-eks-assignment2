#!/usr/bin/env bash

set -euo pipefail

# Create an EKS Access Entry for an IAM principal and associate admin policy.
# This script is SSO-friendly: when invoked from an AWS SSO session (assumed-role),
# it resolves the correct full IAM role ARN (including path like /aws-reserved/sso.amazonaws.com/NAME).
#
# Inputs (env vars or flags):
#   CLUSTER_NAME (required)
#   REGION (defaults from AWS_REGION/AWS_DEFAULT_REGION)
#   ADMIN_ROLE_ARN (optional, if you want to specify principal directly)
#   ADMIN_PROFILE (optional; if set, "aws --profile" will be used)
#
# Usage examples:
#   CLUSTER_NAME=innovatemart-sandbox REGION=us-east-1 ./create-eks-access-entry.sh
#   ./create-eks-access-entry.sh -c innovatemart-sandbox -r us-east-1
#   ./create-eks-access-entry.sh -c innovatemart-sandbox -p my-sso-profile

PROFILE_ARGS=()

while getopts ":c:r:p:a:h" opt; do
  case $opt in
    c) CLUSTER_NAME="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    p) ADMIN_PROFILE="$OPTARG" ;;
    a) ADMIN_ROLE_ARN="$OPTARG" ;;
    h)
      echo "Usage: $0 -c <cluster-name> [-r <region>] [-p <aws-profile>] [-a <admin-role-arn>]";
      exit 0
      ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 2 ;;
  esac
done

if [[ -n "${ADMIN_PROFILE:-}" ]]; then
  PROFILE_ARGS=(--profile "$ADMIN_PROFILE")
fi

if [[ -z "${CLUSTER_NAME:-}" ]]; then
  echo "CLUSTER_NAME is required (use -c)." >&2
  exit 2
fi

REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-}}}"
if [[ -z "$REGION" ]]; then
  echo "REGION is required (set AWS_REGION or pass -r)." >&2
  exit 2
fi

echo "Cluster: $CLUSTER_NAME  Region: $REGION"

# Verify cluster exists and get its account id
CLUSTER_ARN=$(aws "${PROFILE_ARGS[@]}" eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.arn' --output text)
CLUSTER_ACCOUNT=$(cut -d: -f5 <<<"$CLUSTER_ARN")

# Determine principal ARN
if [[ -n "${ADMIN_ROLE_ARN:-}" ]]; then
  PRINCIPAL_ARN="$ADMIN_ROLE_ARN"
else
  CALLER_ARN=$(aws "${PROFILE_ARGS[@]}" sts get-caller-identity --query Arn --output text)
  ACCOUNT_ID=$(aws "${PROFILE_ARGS[@]}" sts get-caller-identity --query Account --output text)

  if [[ "$ACCOUNT_ID" != "$CLUSTER_ACCOUNT" ]]; then
    echo "The current session account ($ACCOUNT_ID) does not match the cluster account ($CLUSTER_ACCOUNT). Use a profile in the cluster's account." >&2
    exit 2
  fi

  if [[ "$CALLER_ARN" == arn:aws:sts::*:assumed-role/* ]]; then
    # Extract the role name from the assumed role ARN, then fetch the full role ARN (with path) from IAM
    ROLE_NAME=$(sed -E 's#^arn:aws:sts::[0-9]+:assumed-role/([^/]+)/.*$#\1#' <<<"$CALLER_ARN")
    echo "Detected SSO assumed role: $ROLE_NAME"
    PRINCIPAL_ARN=$(aws "${PROFILE_ARGS[@]}" iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
  elif [[ "$CALLER_ARN" == arn:aws:iam::*:user/* ]]; then
    PRINCIPAL_ARN="$CALLER_ARN"
  elif [[ "$CALLER_ARN" == arn:aws:iam::*:role/* ]]; then
    PRINCIPAL_ARN="$CALLER_ARN"
  else
    echo "Unsupported caller principal: $CALLER_ARN" >&2
    exit 2
  fi
fi

echo "Using principal ARN: $PRINCIPAL_ARN"

# Sanity check the principal
if [[ "$PRINCIPAL_ARN" == arn:aws:iam::*:role/* ]]; then
  ROLE_PART=${PRINCIPAL_ARN#arn:aws:iam::*:role/}
  ROLE_NAME=${ROLE_PART##*/}
  aws "${PROFILE_ARGS[@]}" iam get-role --role-name "$ROLE_NAME" >/dev/null
elif [[ "$PRINCIPAL_ARN" == arn:aws:iam::*:user/* ]]; then
  USER_NAME=${PRINCIPAL_ARN##*/}
  aws "${PROFILE_ARGS[@]}" iam get-user --user-name "$USER_NAME" >/dev/null
else
  echo "Principal is neither an IAM role nor user ARN: $PRINCIPAL_ARN" >&2
  exit 2
fi

# Create the access entry (idempotent)
set +e
aws "${PROFILE_ARGS[@]}" eks create-access-entry \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION" \
  --principal-arn "$PRINCIPAL_ARN"
CREATE_RC=$?
set -e

if [[ $CREATE_RC -ne 0 ]]; then
  echo "Note: create-access-entry returned non-zero (possibly already exists). Continuing to associate policy..."
fi

# Associate cluster-admin policy scoped to cluster
aws "${PROFILE_ARGS[@]}" eks associate-access-policy \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION" \
  --principal-arn "$PRINCIPAL_ARN" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

echo "Listing access entries:"
aws "${PROFILE_ARGS[@]}" eks list-access-entries --cluster-name "$CLUSTER_NAME" --region "$REGION"

echo "Done. Now update kubeconfig and test:"
echo "  aws ${ADMIN_PROFILE:+--profile $ADMIN_PROFILE }eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"
echo "  kubectl auth can-i get pods --all-namespaces"
