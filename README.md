# InnovateMart Project Bedrock 

**Project Type:** Cloud-Native E-commerce Infrastructure  
**Region:** EU-West-1 (Ireland)

## What I Built

I took the AWS retail store sample application and built a production-grade infrastructure using modern cloud-native practices. This demonstrates implementation with proper load balancing, security, and scalability.

The result is a fully functional e-commerce platform running on Amazon EKS with Application Load Balancer integration.

## My Implementation

### Infrastructure Decisions I Made
- **ARM-based instances** (t4g.medium) - Optimal performance for containerized workloads
- **Application Load Balancer** - Load balancing with health checks and auto-scaling
- **AWS Load Balancer Controller** - Native Kubernetes integration for ALB management
- **External Secrets Operator** - Secure integration with AWS Secrets Manager
- **Micro RDS instances** - Right-sized databases for the workload
- **Public subnets only** - Simplified networking for development environment
- **EU-West-1 deployment** - Better for European users and GDPR compliance

### Architecture
```
Internet → ALB DNS → Application Load Balancer → Target Groups → Pods
├── UI Pod (React) → Internal Services
├── Catalog Pod → MySQL RDS
├── Orders Pod → PostgreSQL RDS
└── Carts Pod → DynamoDB

Supporting Infrastructure:
├── AWS Load Balancer Controller (Kubernetes Ingress → ALB)
├── External Secrets Operator (AWS Secrets Manager → K8s Secrets)
├── IRSA (IAM Roles for Service Accounts)
└── VPC with Public Subnets
```

## Code Structure
```
innovatemart-bedrock/
├── terraform/
│   ├── config.yaml               # Centralized configuration
│   ├── state-bootstrap/          # S3 & DynamoDB setup
│   ├── envs/sandbox/            # Main EKS infrastructure
│   ├── envs/operators/          # ALB controller setup
│   └── modules/                 # Reusable components
├── k8s/base/                    # Kubernetes manifests
├── scripts/                     # Deployment automation
└── backup/github-workflows/     # CI/CD (stored for later)
```

## Deployment Process

### Initial Setup
```bash
# 1. Configure AWS credentials
aws configure
# Region: eu-west-1

# 2. Bootstrap state management
cd innovatemart-bedrock/terraform/state-bootstrap
terraform init && terraform apply

# 3. Deploy core infrastructure (EKS, RDS, DynamoDB)
cd ../envs/sandbox
terraform init && terraform apply
# Wait 15-20 minutes for EKS cluster

# 4. Deploy ALB Controller and operators
cd ../operators
cat > terraform.tfvars << EOF
cluster_name = "innovatemart-sandbox"
aws_region = "eu-west-1"
manage_ui_ingress = true
EOF
terraform init && terraform apply

# 5. Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name innovatemart-sandbox

# 6. Deploy applications
cd ../../
kubectl apply -f k8s/base/namespaces/retail-store.yaml
kubectl apply -f k8s/operators/external-secrets/clustersecretstore.yaml
kubectl apply -f k8s/base/config/external-secrets/
kubectl apply -f k8s/base/services/
kubectl apply -f k8s/base/deployments/
```

### Commands
```bash
# Access the cluster
aws eks update-kubeconfig --region eu-west-1 --name innovatemart-sandbox

# Check application status
kubectl get pods -n retail-store
kubectl get ingress -n retail-store

# Get application URL
ALB_DNS=$(kubectl get ingress ui-alb-ingress -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_DNS"

# View application logs
kubectl logs -n retail-store deployment/ui
```

## Key Features

✅ **Load Balancing** - AWS Application Load Balancer with health checks  
✅ **Kubernetes Native** - AWS Load Balancer Controller for seamless ALB integration  
✅ **Security** - VPC isolation, RBAC, encrypted secrets, least-privilege IAM  
✅ **Infrastructure as Code** - Everything defined in Terraform with remote state  
✅ **External Secrets Management** - AWS Secrets Manager integration via operators  
✅ **Production Patterns** - Health checks, proper resource limits, IRSA authentication  
✅ **Scalable Architecture** - Ready for horizontal pod autoscaling and multi-node clusters

## Application Access

**Access via Custom Domain (Free):**
```bash
# Primary access with custom domain
https://innovatemarts.publicvm.com

# Check domain resolution
nslookup innovatemarts.publicvm.com
```

**Access via Application Load Balancer:**
```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress ui-alb-ingress -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_DNS"

# Check ingress status
kubectl get ingress -n retail-store

# Check ALB in AWS Console
aws elbv2 describe-load-balancers --region eu-west-1
```

**Free Domain Setup:**
I used [FreeDomain](https://freedomain.one) to obtain `innovatemarts.publicvm.com` at no cost:
1. Registered at freedomain.one
2. Selected `publicvm.com` as base domain
3. Created subdomain `innovatemarts`
4. Added CNAME record pointing to ALB DNS
5. Configured ALB ingress for custom domain

**Example ALB DNS:**
```
http://k8s-retailst-uialbingr-1234567890-123456789.eu-west-1.elb.amazonaws.com
```

## Troubleshooting Common Issues

**ALB not accessible:**
```bash
# Check ingress status
kubectl describe ingress ui-alb-ingress -n retail-store

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify ALB exists in AWS
aws elbv2 describe-load-balancers --region eu-west-1
```

**Application returning 500 errors:**
```bash
# Check all pods are running
kubectl get pods -n retail-store

# Check service connectivity
kubectl exec -n retail-store deployment/ui -- curl http://catalog-svc:80/health
kubectl exec -n retail-store deployment/ui -- curl http://orders-svc:80/actuator/health
kubectl exec -n retail-store deployment/ui -- curl http://carts-svc:80/actuator/health
```

**Pods stuck in Pending state:**
```bash
kubectl describe pod [pod-name] -n retail-store
# Usually indicates resource constraints or image pull issues
```

**External Secrets not syncing:**
```bash
kubectl describe clustersecretstore innovatemart-cluster-secret-store
# Check IRSA permissions and AWS Secrets Manager access
```

## Security Implementation

- **Network Security**: VPC with security groups restricting database access to VPC CIDR only
- **Identity & Access**: OIDC for service accounts, IAM roles with least-privilege policies (IRSA)
- **Secrets Management**: AWS Secrets Manager integration via External Secrets Operator
- **Load Balancer Security**: ALB with proper security group configurations
- **Container Security**: Non-root users, read-only filesystems, dropped Linux capabilities
- **Kubernetes RBAC**: Service-specific permissions and namespace isolation

## Monitoring & Operations

- **Health Monitoring**: Kubernetes readiness and liveness probes on all services
- **Load Balancer Monitoring**: ALB health checks and target group monitoring
- **Centralized Logging**: CloudWatch integration for application and system logs
- **Resource Monitoring**: Container CPU and memory usage tracking
- **Infrastructure Monitoring**: EKS cluster metrics and ALB performance metrics

## Domain & SSL Implementation

**Free Domain Service:**
- **Provider**: FreeDomain (freedomain.one)
- **Domain**: `innovatemarts.publicvm.com`
- **Cost**: Free subdomain service
- **DNS Management**: External CNAME pointing to ALB
- **SSL**: AWS Certificate Manager (ACM) for HTTPS

**Configuration:**
```bash
# Configure domain in operators
cd terraform/envs/operators
cat > terraform.tfvars << EOF
ingress_hostname = "innovatemarts.publicvm.com"
manage_ui_ingress = true
EOF
terraform apply
```

## Future Enhancements

- **CI/CD Pipeline**: GitHub Actions workflows (stored in backup/ directory)
- **Multi-Environment**: Production and staging environment configurations
- **Monitoring Stack**: Prometheus and Grafana integration
- **Auto Scaling**: Horizontal Pod Autoscaler and Cluster Autoscaler
- **Multi-AZ**: High availability across multiple availability zones

## License & Attribution

**License:** MIT License  
**Base Application:** AWS Retail Store Sample (Enhanced & Customized)

This project demonstrates modern cloud-native development practices and serves as a reference implementation for production-grade microservices on AWS EKS.

## Clean Up

When you're done testing:
```bash
# Destroy infrastructure
cd terraform/envs/sandbox
terraform destroy

# Clean up state storage
cd ../../state-bootstrap
terraform destroy
```

This setup has been tested extensively and provides a solid foundation for cloud-native applications on AWS.