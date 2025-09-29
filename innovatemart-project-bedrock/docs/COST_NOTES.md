# COST MANAGEMENT AND OPTIMIZATION NOTES

Docs index: [Architecture](./ARCHITECTURE.md) | [Deployment Guide](./DEPLOYMENT_GUIDE.md) | [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) | [CI/CD](./CI_CD.md) | [Cost Notes](./COST_NOTES.md) | [Back to root README](../../README.md)

## Overview
This document outlines the cost considerations and optimization strategies for deploying the InnovateMart retail-store-sample-app on AWS using EKS. The goal is to ensure that the infrastructure is cost-effective while meeting the application's performance and scalability requirements.

## Infrastructure Costs
1. **EKS Cluster**:
   - Choose the smallest instance types for the EKS worker nodes (e.g., `t3.small` or `t3.micro`).
   - Use spot instances where possible to reduce costs.

2. **RDS Instances**:
   - For PostgreSQL (orders service) and MySQL (catalog service), select the `db.t3.micro` instance type for development and testing environments.
   - Enable storage autoscaling to avoid over-provisioning.
   - Use single-AZ deployments for non-production workloads to save costs.

3. **DynamoDB**:
   - Use on-demand capacity mode for the carts service to avoid paying for unused provisioned capacity.
   - Monitor usage and adjust read/write capacity settings as necessary.

## Networking Costs
1. **VPC and Subnets**:
   - Utilize a single VPC with public and private subnets to minimize data transfer costs.
   - Avoid unnecessary NAT gateways; consider using VPC endpoints for S3 and DynamoDB to reduce data transfer costs.

2. **Load Balancers**:
   - Use Application Load Balancers (ALB) only when necessary. For internal services, consider using ClusterIP or NodePort services to avoid incurring ALB costs.

## Monitoring and Optimization
1. **Cost Monitoring**:
   - Set up AWS Budgets and Cost Explorer to monitor spending and receive alerts when approaching budget thresholds.
   - Regularly review AWS Cost and Usage Reports to identify areas for cost savings.

2. **Resource Optimization**:
   - Implement auto-scaling for EKS nodes and RDS instances to adjust capacity based on demand.
   - Regularly review and clean up unused resources (e.g., old snapshots, unused IAM roles).

## Conclusion
By carefully selecting instance types, utilizing managed services efficiently, and continuously monitoring costs, InnovateMart can maintain a cost-effective cloud infrastructure while supporting the retail-store-sample-app's growth and scalability needs.

Back: [Architecture](./ARCHITECTURE.md) · [Deployment Guide](./DEPLOYMENT_GUIDE.md) · [CI/CD](./CI_CD.md)
