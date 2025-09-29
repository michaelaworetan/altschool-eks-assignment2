# Domain Setup Guide

## Option 1: Using Your Own Domain

### Step 1: Register Domain
- Use any domain registrar (GoDaddy, Namecheap, etc.)
- Or use free services like Freenom (freenom.com)

### Step 2: Create Route53 Hosted Zone
```bash
# Create hosted zone
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s)

# Note the Zone ID from output
```

### Step 3: Update Domain Nameservers
- Copy the 4 nameservers from Route53 hosted zone
- Update your domain registrar's nameserver settings

### Step 4: Deploy with Domain
```bash
cd terraform/envs/operators

# Create terraform.tfvars
cat > terraform.tfvars << EOF
route53_zone_id = "Z1234567890ABC"  # Your Zone ID
ingress_hostname = "shop.yourdomain.com"
manage_ui_ingress = true
EOF

terraform apply
```

## Option 2: Using ALB DNS Name (No Domain Required)

### Step 1: Deploy without Domain
```bash
cd terraform/envs/operators

# Create terraform.tfvars
cat > terraform.tfvars << EOF
manage_ui_ingress = true
EOF

terraform apply
```

### Step 2: Get ALB URL
```bash
terraform output alb_dns_name
# Access via: http://[ALB-DNS-NAME]
```

## Option 3: Free Domain Setup (Freenom)

### Step 1: Register Free Domain
1. Go to freenom.com
2. Search for available domain (.tk, .ml, .ga, .cf)
3. Register for free (12 months)

### Step 2: Configure DNS
1. In Freenom dashboard, go to "Manage Domain"
2. Select "Management Tools" → "Nameservers"
3. Choose "Use custom nameservers"
4. Enter Route53 nameservers from Step 2 above

### Step 3: Wait for Propagation
- DNS propagation takes 24-48 hours
- Test with: `nslookup yourdomain.tk`

## SSL Certificate Process

The Terraform configuration automatically:
1. **Creates ACM certificate** for your domain
2. **Validates via DNS** (if Route53 zone provided)
3. **Attaches to ALB** for HTTPS
4. **Redirects HTTP to HTTPS**

## Verification Commands

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn [CERT-ARN]

# Check ALB
aws elbv2 describe-load-balancers

# Test SSL
curl -I https://yourdomain.com

# Check DNS resolution
nslookup yourdomain.com
```

## Troubleshooting

### Certificate Pending Validation
```bash
# Check DNS validation records
aws route53 list-resource-record-sets --hosted-zone-id [ZONE-ID]

# Manual validation (if needed)
aws acm describe-certificate --certificate-arn [CERT-ARN]
```

### ALB Not Created
```bash
# Check ingress status
kubectl describe ingress ui-ingress -n retail-store

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Domain Not Resolving
```bash
# Check nameservers
dig NS yourdomain.com

# Check propagation
dig yourdomain.com @8.8.8.8
```