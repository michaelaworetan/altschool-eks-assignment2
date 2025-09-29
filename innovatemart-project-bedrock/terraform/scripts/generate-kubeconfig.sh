#!/bin/bash

# This script generates the kubeconfig file for accessing the EKS cluster.

set -e

# Allow overriding via env vars or positional args; fall back to sane defaults
CLUSTER_NAME=${CLUSTER_NAME:-${1:-innovatemart-sandbox}}
REGION=${REGION:-${2:-eu-west-1}}

# Update kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "Kubeconfig generated for cluster: $CLUSTER_NAME in region: $REGION"
