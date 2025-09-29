#!/usr/bin/env bash
# Destroy all environments in a safe order.
# Order: operators-addons -> operators-iam -> operators (legacy) -> sandbox
# Supports AWS_PROFILE and REGION; prompts for confirmation.

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
REGION=${REGION:-eu-west-1}
PROFILE_ARG=${1:-}
if [[ -n "$PROFILE_ARG" ]]; then
  export AWS_PROFILE="$PROFILE_ARG"
fi

say() { echo -e "[destroy-all] $*"; }
run_tf() {
  local dir="$1"; shift
  if [[ -d "$dir" ]]; then
    (cd "$dir" && terraform init -upgrade >/dev/null && terraform destroy -auto-approve "$@") || true
  fi
}

check_state() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    local count
    # List resources remaining in state (0 indicates empty/fully destroyed)
    count=$(cd "$dir" && terraform init -upgrade >/dev/null && terraform state list 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    say "State check for $(basename "$dir"): ${count} resources in state"
  fi
}

cat <<CONFIRM
This will destroy all Terraform-managed resources for InnovateMart in the following order:
  1) operators-addons (k8s/helm)
  2) operators-iam (IAM/IRSA)
  3) operators (legacy combined stack, if present)
  4) sandbox (VPC, EKS, RDS, DynamoDB, Secrets)

AWS_PROFILE: ${AWS_PROFILE:-<unset>}
REGION:      ${REGION}

WARNING: This is destructive and may remove databases (RDS), tables (DynamoDB), and secrets.
Consider creating snapshots/backups before proceeding.
CONFIRM

read -r -p "Type 'DESTROY' to continue: " ANSWER
if [[ "$ANSWER" != "DESTROY" ]]; then
  say "Aborted by user."
  exit 1
fi

say "Destroying operators-addons..."
run_tf "$ROOT_DIR/terraform/envs/operators-addons" -var aws_region="$REGION"
check_state "$ROOT_DIR/terraform/envs/operators-addons"

say "Destroying operators-iam..."
run_tf "$ROOT_DIR/terraform/envs/operators-iam" -var aws_region="$REGION"
check_state "$ROOT_DIR/terraform/envs/operators-iam"

say "Destroying legacy operators (if present)..."
run_tf "$ROOT_DIR/terraform/envs/operators" -var aws_region="$REGION"
check_state "$ROOT_DIR/terraform/envs/operators"

say "Destroying sandbox..."
run_tf "$ROOT_DIR/terraform/envs/sandbox" -var aws_region="$REGION"
check_state "$ROOT_DIR/terraform/envs/sandbox"

say "Done."
