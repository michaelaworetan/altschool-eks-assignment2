# DuckDNS Setup Guide

## What is DuckDNS?
DuckDNS is a **free dynamic DNS service** that gives you a domain name (like `innovatemarts.duckdns.org`) that points to your server's IP address.

## Why Use DuckDNS?
- **Free domain** (no cost vs $12/year for regular domains)
- **Dynamic updates** (automatically updates when your server IP changes)
- **Easy setup** (just need email to register)

## Step 1: Register Domain

1. **Go to duckdns.org**
2. **Sign in** with Google/GitHub/Reddit account
3. **Create subdomain**: Enter your desired name (e.g., "innovatemarts")
4. **Your domain**: `innovatemarts.duckdns.org`
5. **Copy token**: Save your DuckDNS token (looks like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

## Step 2: Configure Terraform

```bash
cd terraform/envs/operators

# Create configuration file
cat > terraform.tfvars << EOF
# DuckDNS Configuration
duckdns_token = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"  # Your token
duckdns_domain = "innovatemarts"  # Your domain (without .duckdns.org)

# Use NodePort (no ALB costs)
manage_ui_ingress = false
EOF

# Apply configuration
terraform apply
```

## Step 3: Verify Setup

```bash
# Check if domain resolves to your node IP
nslookup innovatemarts.duckdns.org

# Get your node IP
kubectl get nodes -o wide

# Test application access
curl http://innovatemarts.duckdns.org:30080
```

## Step 4: Automatic Updates (Recommended)

### Option A: Kubernetes CronJob
```bash
# Edit the secret with your token
kubectl edit secret duckdns-secret -n retail-store
# Replace YOUR_DUCKDNS_TOKEN_HERE with your actual token

# Deploy automatic updater
kubectl apply -f k8s/base/cronjobs/duckdns-updater.yaml

# Check if it's running
kubectl get cronjobs -n retail-store
```

### Option B: Manual Script
```bash
# Make script executable
chmod +x scripts/update-duckdns.sh

# Run manually when needed
DUCKDNS_TOKEN="your_token" ./scripts/update-duckdns.sh

# Or run continuously in background
DUCKDNS_TOKEN="your_token" nohup ./scripts/auto-update-duckdns.sh &
```

## How DNS Updates Work

### The Problem
```bash
# Your EKS node IP can change when:
# - AWS restarts the instance
# - You scale the cluster
# - Instance gets replaced

# Before: innovatemarts.duckdns.org → 3.248.123.45 ✅
# After restart: Node IP changes to 3.248.200.100
# But DuckDNS still points to: 3.248.123.45 ❌
# Result: Your site is unreachable
```

### The Solution
```bash
# Automatic updater detects IP change and calls:
curl "https://www.duckdns.org/update?domains=innovatemarts&token=YOUR_TOKEN&ip=3.248.200.100"

# Now: innovatemarts.duckdns.org → 3.248.200.100 ✅
# Your site works again
```

## Troubleshooting

### Domain Not Resolving
```bash
# Check current DNS
nslookup innovatemarts.duckdns.org

# Get current node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
echo "Node IP: $NODE_IP"

# Update manually
curl "https://www.duckdns.org/update?domains=innovatemarts&token=YOUR_TOKEN&ip=$NODE_IP"
```

### Site Not Accessible
```bash
# Check if port 30080 is open
telnet innovatemarts.duckdns.org 30080

# Check security group
SG_ID=$(aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/innovatemart-sandbox,Values=owned" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# Allow NodePort access
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 30080 \
  --cidr 0.0.0.0/0
```

### Automatic Updater Not Working
```bash
# Check CronJob status
kubectl get cronjobs -n retail-store

# Check recent jobs
kubectl get jobs -n retail-store

# Check logs
kubectl logs -n retail-store job/duckdns-updater-[timestamp]

# Check secret
kubectl get secret duckdns-secret -n retail-store -o yaml
```

## Cost Comparison

| Service | DuckDNS | Route53 + Domain |
|---------|---------|------------------|
| Domain | Free | $12/year |
| DNS Hosting | Free | $0.50/month |
| **Total** | **$0** | **$18/year** |

## Limitations

- **Subdomain only**: You get `yourname.duckdns.org`, not `yourname.com`
- **No SSL by default**: Need to set up SSL separately if needed
- **Dynamic DNS**: Designed for changing IPs, not static hosting

## Next Steps

After DuckDNS is working:
1. **Test your application**: `http://innovatemarts.duckdns.org:30080`
2. **Set up monitoring**: Check if automatic updates work
3. **Consider SSL**: Add CloudFront or reverse proxy for HTTPS
4. **Document your domain**: Share the URL with your team

Your application is now accessible via a free domain name that automatically updates when your server IP changes!