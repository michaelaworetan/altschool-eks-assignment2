# Operators Environment Providers
# Purpose: Configure providers for ALB controller and ingress setup

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

locals {
  operators_region       = coalesce(var.aws_region, try(data.terraform_remote_state.sandbox.outputs.aws_region, null), "eu-west-1")
  operators_cluster_name = coalesce(var.cluster_name, try(data.terraform_remote_state.sandbox.outputs.eks_cluster_name, null), "innovatemart-sandbox")
}

provider "aws" {
  region = local.operators_region
}

data "aws_eks_cluster" "this" {
  name = local.operators_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.operators_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}