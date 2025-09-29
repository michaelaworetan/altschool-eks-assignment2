variable "cluster_name" {
	description = "EKS cluster name (for naming and optional tagging)"
	type        = string
}

variable "oidc_host" {
	description = "OIDC issuer host for the EKS cluster (without https://)"
	type        = string
}

variable "service_account_namespace" {
	description = "Namespace of the service account running the ALB controller"
	type        = string
	default     = "kube-system"
}

variable "service_account_name" {
	description = "Service account name for the ALB controller"
	type        = string
	default     = "aws-load-balancer-controller"
}
