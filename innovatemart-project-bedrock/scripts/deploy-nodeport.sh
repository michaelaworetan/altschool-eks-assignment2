#!/bin/bash

# Complete EKS Deployment Script - NodePort Only (No ALB)
# Simplified deployment without operators/ALB controller

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting EKS deployment with NodePort..."

# Step 1: Bootstrap state storage
echo "📦 Step 1: Bootstrapping Terraform state storage..."
cd "$PROJECT_ROOT/terraform/state-bootstrap"
terraform init
terraform apply -auto-approve
echo "✅ State storage created"

# Step 2: Deploy main infrastructure ONLY
echo "🏗️  Step 2: Deploying main infrastructure (EKS, VPC, RDS)..."
cd "$PROJECT_ROOT/terraform/envs/sandbox"
terraform init
terraform apply -auto-approve
echo "✅ Main infrastructure deployed"

# Step 3: Configure kubectl
echo "🔧 Step 3: Configuring kubectl..."
aws eks update-kubeconfig --region eu-west-1 --name innovatemart-sandbox
echo "✅ kubectl configured"

# Step 4: Deploy applications
echo "📱 Step 4: Deploying applications..."
cd "$PROJECT_ROOT"
chmod +x scripts/deploy-app.sh
./scripts/deploy-app.sh
echo "✅ Applications deployed"

# Step 5: Configure security group for NodePort
echo "🔒 Step 5: Opening NodePort 30080..."
SG_ID=$(aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/innovatemart-sandbox,Values=owned" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 30080 --cidr 0.0.0.0/0 2>/dev/null || echo "Port 30080 already open"
echo "✅ NodePort 30080 opened"

# Step 6: Get node IP and show access info
echo "🌐 Step 6: Getting access information..."
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Summary:"
echo "- EKS Cluster: innovatemart-sandbox"
echo "- Node IP: $NODE_IP"
echo "- NodePort: 30080"
echo ""
echo "🔗 Access your application:"
echo "http://$NODE_IP:30080"
echo ""
echo "📊 Check status:"
echo "kubectl get pods -n retail-store"
echo "kubectl get service ui-nodeport -n retail-store"
echo ""
echo "🌐 For DuckDNS setup:"
echo "1. Get free domain at duckdns.org"
echo "2. Update domain to point to: $NODE_IP"
echo "3. Access via: http://yourdomain.duckdns.org:30080"