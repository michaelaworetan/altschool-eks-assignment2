#!/bin/bash

set -e

# This script configures the AWS authentication for the EKS cluster.

CLUSTER_NAME="innovatemart-sandbox" 
REGION="eu-west-1"

# Get the current AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get the IAM role ARN for the EKS worker nodes
NODE_ROLE_ARN=$(aws iam get-role --role-name "${CLUSTER_NAME}-node-group-role" --query 'Role.Arn' --output text)
DEV_USER_ARN=arn:aws:iam::"$ACCOUNT_ID":user/innovatemart-dev-ro

# Update the kubeconfig file
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Create the aws-auth ConfigMap
cat > /tmp/aws-auth.yaml <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${NODE_ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: ${DEV_USER_ARN}
      username: innovatemart-dev-ro
      groups:
        - view-only
YAML

echo "AWS authentication configured for the EKS cluster."

# Apply the aws-auth ConfigMap to the cluster
kubectl apply -f /tmp/aws-auth.yaml
