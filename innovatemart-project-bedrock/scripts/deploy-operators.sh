#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

echo "Installing AWS Load Balancer Controller..."
"$REPO_ROOT/terraform/scripts/install-aws-load-balancer-controller.sh"

echo "(Optional) Install External Secrets Operator: see k8s/operators/external-secrets for configuration."
echo "Operators deployed successfully."