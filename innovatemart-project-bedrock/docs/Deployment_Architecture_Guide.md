# Deployment & Architecture Guide: InnovateMart Retail Store

Docs index: [Architecture](./ARCHITECTURE.md) | [Deployment Guide](./DEPLOYMENT_GUIDE.md) | [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) | [CI/CD](./CI_CD.md) | [Cost Notes](./COST_NOTES.md) | [Back to root README](../../README.md)

This short guide covers the architecture, how to access the running app, and how a read-only developer can connect to the EKS cluster. It also summarizes the bonus objectives implemented.

## 1) Architecture Overview

- Core platform: Amazon EKS (v1.33) in AWS region (default: us-east-1), running a minimal node group for cost control.
- Network: One VPC with 2 public + 2 private subnets. Public subnets are tagged for ALB; most workloads run in private subnets.
- Microservices (namespace `retail-store`):
  - ui (frontend)
  - catalog (MySQL on RDS)
  - orders (PostgreSQL on RDS)
  - carts (DynamoDB)
- Data stores (managed):
  - RDS MySQL for catalog, RDS PostgreSQL for orders (small instance sizes; dev-friendly).
  - DynamoDB table `carts` for the carts service (on-demand; GSI on customerId).
- Traffic and exposure:
  - AWS Load Balancer Controller (ALB) for optional HTTPS ingress via ACM and Route 53.
  - NodePort fallback for the UI when ALB creation is not permitted.
- Secrets and identity:
  - External Secrets Operator (ESO) pulls app secrets from AWS Secrets Manager (`retail/*`).
  - IRSA (IAM Roles for Service Accounts) for ALB controller, ExternalDNS, ESO, and carts service.
  - EKS OIDC provider configured for IRSA.
- Access and RBAC:
  - EKS Access Entries and aws-auth mapping grant cluster access.
  - A dedicated read-only IAM user (`innovatemart-dev-ro`) is mapped to Kubernetes view-only RBAC.
- CI/CD:
  - GitHub Actions with OIDC to assume an AWS role (no long-lived keys).
  - Workflows: Terraform plan on PRs, apply on `main`, and a k8s deploy workflow for manifests.
- Cost posture:
  - Small node group, single-AZ RDS in dev, DynamoDB on-demand, optional ALB.

## 2) How to access the running application

Choose the option that matches your environment.

### Option A: HTTPS via ALB + Route 53 + ACM (if enabled)
- Pre-req: `ingress_hostname` and `route53_zone_id` configured in the operators stack.
- Look up the UI endpoint:
  ```bash
  kubectl get ingress -n retail-store
  # or, if using a LoadBalancer service instead of Ingress
  kubectl get svc ui -n retail-store -o wide
  ```
- Access the app:
  - Via DNS: https://YOUR_INGRESS_HOSTNAME/
  - If ExternalDNS is disabled, use the ALB DNS name shown by `kubectl get ingress`.

### Option B: NodePort fallback (when ALB is restricted)
- Get the UI NodePort and any node’s public IP:
  ```bash
  kubectl get svc ui-nodeport -n retail-store
  kubectl get nodes -o wide
  ```
- Construct the URL: `http://<NODE_PUBLIC_IP>:<NODE_PORT>/`
- For quick test on a single-node dev cluster, either node IP will work.

Note on our environment:
- ALB provisioning was blocked at the AWS account level (service-linked role/ALB creation not permitted). As a result, Ingress with ALB could not be used.
- We implemented a NodePort Service (`ui-nodeport`) instead of an Ingress. The service exposes port 80 mapped to container port 8080, with a fixed nodePort `30080`:
  - File: `../k8s/base/services/ui-nodeport.yaml`
  - Access example: `http://<any-node-public-ip>:30080/`
  - This allowed external access without depending on ALB while keeping the rest of the stack unchanged.

Route 53 DNS (NodePort friendly name)
- To provide a stable DNS name while using NodePort, we created an A record in Route 53 that points to both node public IPs. Example via CLI:
  ```bash
  HOSTED_ZONE_ID=Z1234567890ABC
  RECORD_NAME=shop.example.com.
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch '{
      "Comment": "Point to EKS nodes for NodePort 30080",
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'"'$RECORD_NAME'"'",
          "Type": "A",
          "TTL": 60,
          "ResourceRecords": [
            {"Value": "<NODE_PUBLIC_IP_1>"},
            {"Value": "<NODE_PUBLIC_IP_2>"}
          ]
        }
      }]
    }'
  ```
  - Get node public IPs from EC2 (console) or programmatically by mapping node instance IDs:
    ```bash
    # List instance IDs from Kubernetes nodes
    for id in $(kubectl get nodes -o jsonpath='{range .items[*]}{.spec.providerID}{"\n"}{end}' | awk -F/ '{print $NF}'); do
      aws ec2 describe-instances --instance-ids "$id" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    done
    ```
  - Caveat: If nodes are replaced, their public IPs change; update the A record accordingly. When account restrictions are lifted, prefer ALB/Ingress for stable endpoints.

## 3) Read-only developer access (innovatemart-dev-ro)

The `innovatemart-dev-ro` IAM user has read-only AWS permissions and view-only Kubernetes RBAC.

1. Receive credentials securely
   - An admin provides the Access Key ID and Secret Access Key for the user (created by Terraform). Store them in your local credential store or environment variables.

2. Configure AWS CLI
   ```bash
   aws configure --profile innovatemart-dev-ro
   # Enter Access Key ID, Secret, and region (e.g., us-east-1)
   ```

3. Generate kubeconfig for EKS
   - Either use the provided helper script:
     ```bash
     innovatemart-project-bedrock/terraform/scripts/generate-kubeconfig.sh
     ```
   - Or use AWS CLI directly:
     ```bash
     aws eks update-kubeconfig \
       --region us-east-1 \
       --name innovatemart-sandbox \
       --profile innovatemart-dev-ro
     ```

4. Verify read-only access
   ```bash
   kubectl get ns
   kubectl get pods -A
   kubectl auth can-i delete pods -A   # should be "no"
   kubectl auth can-i get pods -A      # should be "yes"
   ```

Notes:
- The IAM policy intentionally limits actions; kube RBAC maps the user to a view-only ClusterRoleBinding.
- If `kubectl` returns Unauthorized, ask an admin to re-run the aws-auth script and ensure your IAM user is mapped.

## 4) Bonus objectives implemented (details)

- IRSA everywhere it matters
  - EKS OIDC provider is created and four roles are bound via service accounts:
    - AWS Load Balancer Controller
    - ExternalDNS (optional, when Route 53 is used)
    - External Secrets Operator
    - carts service (DynamoDB table access restricted to `carts` and its GSIs)
- Secrets without plaintext in Git
  - External Secrets Operator is installed in `kube-system`. A ClusterSecretStore references AWS Secrets Manager.
  - Secrets: `retail/catalog`, `retail/orders`, and `retail/carts` hold DB URLs and table names. ESO syncs them to Kubernetes Secrets on demand.
- Optional HTTPS and DNS
  - ACM certificate is DNS-validated via Route 53 for `ingress_hostname`. ALB Controller provisions the ALB; ExternalDNS manages A/AAAA records (zone-scoped IAM policy).
  - If ALB creation is blocked at the account level, UI is still reachable via a NodePort service.
- GitHub Actions OIDC with least-privilege
  - Workflows assume an AWS role using GitHub OIDC (no static AWS keys).
  - A dedicated read-only policy enables Terraform plan to read cloud resources; apply runs with the provisioning role.
  - Concurrency and environment scoping are enabled to avoid overlapping applies.
- SSO-friendly and developer experience
  - Helper scripts: kubeconfig generation; aws-auth configuration to grant access entries and RBAC.
  - Read-only IAM user (`innovatemart-dev-ro`) and ClusterRoleBinding to view-only.
- Cost safeguards
  - Single small node group; on-demand DynamoDB; single-AZ RDS in dev; ALB kept optional.

## 5) Quick troubleshooting

- Can’t reach UI via HTTPS: verify ALB controller is running, ACM certificate is issued, and Route 53 records exist. Fall back to NodePort to confirm app health.
- `kubectl` unauthorized: ensure your IAM user is mapped in aws-auth and that your CLI is using the correct profile.
- ESO not syncing: confirm EKS OIDC provider exists and the ESO IRSA role has Secrets Manager read permissions.

---
This guide is intentionally concise (≤2 pages). See [Architecture](./ARCHITECTURE.md) and [Deployment Guide](./DEPLOYMENT_GUIDE.md) for deeper details.

Next: [CI/CD](./CI_CD.md)
