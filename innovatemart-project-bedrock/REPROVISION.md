# Fresh start: destroy and re-provision

This guide resets all Terraform-managed resources, then brings the environment back up cleanly.

## 0) Destroy in safe order

Use the helper (accepts optional profile as first argument; REGION env var is supported):

```bash
cd innovatemart-project-bedrock/terraform/scripts
./destroy-all.sh [your-admin-sso]
```

## 1) Recreate sandbox (VPC, EKS, RDS, DynamoDB, Secrets)

```bash
export AWS_PROFILE=your-admin-sso
cd ../envs/sandbox
terraform init -upgrade
terraform apply
```

When EKS is ACTIVE, configure kubeconfig:

```bash
cd ../../scripts
./generate-kubeconfig.sh innovatemart-sandbox eu-west-1 your-admin-sso
kubectl get nodes -A
```

## 2) Create IAM/IRSA (operators-iam)

Fetch OIDC issuer host (without https://):

```bash
OIDC_HOST=$(aws eks describe-cluster \
  --name innovatemart-sandbox \
  --region eu-west-1 \
  --query 'cluster.identity.oidc.issuer' --output text | sed 's#^https://##')
```

Apply IAM:

```bash
cd ../envs/operators-iam
terraform init -upgrade
terraform apply \
  -var cluster_name=innovatemart-sandbox \
  -var oidc_host="$OIDC_HOST"
```

Note: If IAM already exists, import it using the commands in `operators-iam/README.md`, then re-apply.

## 3) Install add-ons (operators-addons)

Collect role ARNs from operators-iam outputs, then:

```bash
cd ../operators-addons
terraform init -upgrade
terraform apply \
  -var cluster_name=innovatemart-sandbox \
  -var alb_controller_role_arn=arn:aws:iam::123456789012:role/innovatemart-sandbox-alb-controller-role \
  -var externaldns_role_arn=arn:aws:iam::123456789012:role/innovatemart-sandbox-externaldns-role \
  -var eso_role_arn=arn:aws:iam::123456789012:role/innovatemart-sandbox-eso-role \
  -var carts_role_arn=arn:aws:iam::123456789012:role/innovatemart-sandbox-carts-role
```

Optionally add DNS/hostname and UI ingress:

```bash
terraform apply \
  -var route53_zone_id=ZABCDEFGHIJKLMN \
  -var ingress_hostname=shop.example.com \
  -var manage_ui_ingress=true
```

## 4) Verify

```bash
kubectl -n kube-system get deploy | egrep 'aws-load-balancer-controller|external-dns|external-secrets'
kubectl -n retail-store get sa carts
kubectl get ingress -A
```

If External Secrets is configured with your SecretStore, check status:
```bash
kubectl get es,externalsecret -A
```

## Safety notes

- Destruction removes RDS instances and DynamoDB tables. Take snapshots/backups if you need to retain data.
- If you previously validated ACM/Route53 records, reusing the same hostname is fine; ExternalDNS will re-create records.
- Ensure your AWS_PROFILE matches the account where your S3 state bucket and DynamoDB lock table live.
