# Architecture Overview

Docs index: [Architecture](./ARCHITECTURE.md) | [Deployment Guide](./DEPLOYMENT_GUIDE.md) | [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) | [CI/CD](./CI_CD.md) | [Cost Notes](./COST_NOTES.md) | [Back to root README](../../README.md)

## Introduction
The InnovateMart retail store application is designed as a microservices architecture deployed on Amazon Elastic Kubernetes Service (EKS). This document provides a detailed overview of the architecture, including the components, their interactions, and the underlying AWS services utilized.

## Architecture Components

### 1. Amazon EKS Cluster
The core of the application is hosted on an Amazon EKS cluster, which manages the Kubernetes control plane and provides a scalable environment for deploying microservices. The cluster is configured with minimal resource utilization to keep costs low, using small instance types for the worker nodes.

### 2. Virtual Private Cloud (VPC)
The EKS cluster is deployed within a Virtual Private Cloud (VPC) that includes:
- **Public Subnets**: For resources that need to be accessible from the internet, such as the Application Load Balancer (ALB).
- **Private Subnets**: For internal resources, including the microservices and databases, ensuring they are not directly exposed to the internet.

### 3. Microservices
The application is composed of several microservices, each responsible for a specific business capability:
- **UI Service**: Serves the frontend application to users.
- **Catalog Service**: Manages product listings and details.
- **Orders Service**: Handles order processing and management.
- **Carts Service**: Manages user shopping carts.

### 4. Managed Persistence Layer
To ensure data durability and scalability, the application utilizes managed AWS services for persistence:
- **Amazon RDS for PostgreSQL**: Used by the Orders Service to store order data.
- **Amazon RDS for MySQL**: Used by the Catalog Service for product information.
- **Amazon DynamoDB**: Utilized by the Carts Service for managing user cart data.

### 5. Networking and Security
The architecture incorporates advanced networking and security practices:
- **AWS Load Balancer Controller**: Manages the ALB for routing traffic to the UI service.
- **IAM Roles and Policies**: Implemented to follow the principle of least privilege, ensuring that services and users have only the permissions they need.
- **Kubernetes Ingress**: Configured to expose the UI service securely via the ALB.

### 6. CI/CD Pipeline
A CI/CD pipeline is established using GitHub Actions to automate the deployment process. The pipeline includes:
- **Terraform Plan**: Triggered on feature branch pushes to validate infrastructure changes.
- **Terraform Apply**: Executed on merges to the main branch to apply the changes.
- **Kubernetes Deployment**: Automates the deployment of microservices to the EKS cluster.

## Conclusion
The architecture of the InnovateMart retail store application is designed to be scalable, secure, and cost-effective. By leveraging AWS managed services and Kubernetes, the application can efficiently handle user traffic while maintaining a focus on resource optimization. This architecture lays a solid foundation for future enhancements and scaling as InnovateMart continues to grow.

Next: [Deployment Guide](./DEPLOYMENT_GUIDE.md)
