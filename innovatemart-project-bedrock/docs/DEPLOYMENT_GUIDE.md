# Deployment Guide for InnovateMart Retail Store Application

Docs index: [Architecture](./ARCHITECTURE.md) | [Deployment Guide](./DEPLOYMENT_GUIDE.md) | [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) | [CI/CD](./CI_CD.md) | [Cost Notes](./COST_NOTES.md) | [Back to root README](../../README.md)

## Prerequisites
Before deploying the application, ensure you have the following:

1. **AWS Account**: An active AWS account with permissions to create and manage EKS, RDS, IAM, and Route 53 resources.
2. **Terraform**: Install Terraform (version 1.0 or higher) on your local machine.
3. **kubectl**: Install kubectl to interact with your Kubernetes cluster.
4. **AWS CLI**: Install the AWS CLI and configure it with your AWS credentials.
5. **Git**: Ensure Git is installed for version control.

## Steps to Deploy

### 1. Clone the Repository
Clone the InnovateMart project repository to your local machine:
```bash
git clone https://github.com/Bamidele0102/retail-store-sample-app.git
cd retail-store-sample-app/innovatemart-project-bedrock
```

### 2. Configure Terraform Variables
Navigate to the `terraform/envs/sandbox` directory and create a `terraform.tfvars` file based on the `terraform.tfvars.example` provided. Update the values as necessary for your environment.

### 3. Initialize Terraform
Run the following command to initialize Terraform and download the necessary providers:
```bash
terraform init
```

### 4. Plan the Infrastructure
Generate an execution plan to review the resources that will be created:
```bash
terraform plan
```

### 5. Apply the Terraform Configuration
Deploy the infrastructure by applying the Terraform configuration:
```bash
terraform apply
```
Confirm the action when prompted.

### 6. Configure kubectl
After the EKS cluster is created, configure kubectl to use the new cluster:
```bash
../../terraform/scripts/generate-kubeconfig.sh
```

### 7. Deploy the Application
Deploy the retail store application to the EKS cluster:
```bash
../scripts/deploy-app.sh
```

### 8. Access the Application
Once the application is deployed, you can access it via the Application Load Balancer (ALB) created in the previous steps. Retrieve the ALB URL using:
```bash
kubectl get services -n retail-store
```
Look for the service associated with the UI component.

## Developer Access
To provide the development team with read-only access to the EKS cluster:

1. Create an IAM user with read-only permissions as defined in the Terraform IAM module.
2. Provide the IAM user credentials and instructions to configure their AWS CLI.

## Conclusion
You have successfully deployed the InnovateMart Retail Store Application on AWS EKS.

Next:
- Review [Deployment Architecture Guide](./Deployment_Architecture_Guide.md) for environment-specific access patterns (ALB vs NodePort).
- See [CI/CD](./CI_CD.md) to understand how changes are deployed via GitHub Actions.
- Consult [Cost Notes](./COST_NOTES.md) to keep the sandbox inexpensive.
