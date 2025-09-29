#!/bin/bash

# Complete EKS Deployment Script
# Runs all terraform configurations in sequence

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting complete EKS deployment..."
echo "Project root: $PROJECT_ROOT"

# Check if DuckDNS configuration exists
if [ ! -f "$PROJECT_ROOT/terraform/envs/operators/terraform.tfvars" ]; then
    echo "❌ Missing DuckDNS configuration!"
    echo "Create terraform/envs/operators/terraform.tfvars with:"
    echo "duckdns_token = \"your_token_here\""
    echo "duckdns_domain = \"innovatemarts\""
    echo "manage_ui_ingress = false"
    exit 1
fi

# Step 1: Bootstrap state storage
echo "📦 Step 1: Bootstrapping Terraform state storage..."
cd "$PROJECT_ROOT/terraform/state-bootstrap"
terraform init
terraform apply -auto-approve
echo "✅ State storage created"

# Step 2: Deploy main infrastructure
echo "🏗️  Step 2: Deploying main infrastructure (EKS, VPC, RDS)..."
cd "$PROJECT_ROOT/terraform/envs/sandbox"
terraform init
terraform apply -auto-approve
echo "✅ Main infrastructure deployed"

# Step 3: Deploy operators
echo "⚙️  Step 3: Deploying operators and DuckDNS..."
cd "$PROJECT_ROOT/terraform/envs/operators"
terraform init
terraform apply -auto-approve
echo "✅ Operators deployed"

# Step 4: Configure kubectl
echo "🔧 Step 4: Configuring kubectl..."
aws eks update-kubeconfig --region eu-west-1 --name innovatemart-sandbox
echo "✅ kubectl configured"

# Step 5: Deploy applications
echo "📱 Step 5: Deploying applications..."
cd "$PROJECT_ROOT"
chmod +x scripts/deploy-app.sh
./scripts/deploy-app.sh
echo "✅ Applications deployed"

# Step 6: Configure security group
echo "🔒 Step 6: Configuring security group..."
SG_ID=$(aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/innovatemart-sandbox,Values=owned" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 30080 --cidr 0.0.0.0/0 2>/dev/null || echo "Port 30080 already open"
echo "✅ Security group configured"

# Step 7: Set up automatic DNS updates
echo "🌐 Step 7: Setting up automatic DNS updates..."
DUCKDNS_TOKEN=$(grep 'duckdns_token' "$PROJECT_ROOT/terraform/envs/operators/terraform.tfvars" | cut -d'"' -f2)
kubectl patch secret duckdns-secret -n retail-store -p "{\"stringData\":{\"token\":\"$DUCKDNS_TOKEN\"}}" 2>/dev/null || echo "Secret already configured"
kubectl apply -f "$PROJECT_ROOT/k8s/base/cronjobs/duckdns-updater.yaml"
echo "✅ Automatic DNS updates configured"

# Final verification
echo "🔍 Final verification..."
sleep 10
kubectl get pods -n retail-store
kubectl get service ui-nodeport -n retail-store

# Get application URL
DUCKDNS_DOMAIN=$(grep 'duckdns_domain' "$PROJECT_ROOT/terraform/envs/operators/terraform.tfvars" | cut -d'"' -f2)
APPLICATION_URL="http://$DUCKDNS_DOMAIN.duckdns.org:30080"

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Summary:"
echo "- EKS Cluster: innovatemart-sandbox"
echo "- Application URL: $APPLICATION_URL"
echo "- Region: eu-west-1"
echo ""
echo "🔗 Access your application:"
echo "curl $APPLICATION_URL"
echo ""
echo "📊 Check status:"
echo "kubectl get pods -n retail-store"
echo "kubectl get cronjobs -n retail-store"