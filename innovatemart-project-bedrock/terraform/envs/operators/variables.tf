# Operators Environment Variables
# Purpose: Configuration overrides for operators deployment

variable "aws_region" {
  description = "Optional override region; if unset, will read from sandbox remote state"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Optional override cluster name; if unset, will read from sandbox remote state"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Public Route 53 hosted zone ID where DNS validation and records will be created (optional)"
  type        = string
  default     = null
}

variable "ingress_hostname" {
  description = "FQDN to expose the UI (e.g., shop.example.com). Optional; if unset, you can use the ALB DNS name."
  type        = string
  default     = null
}

variable "manage_ui_ingress" {
  description = "If true, Terraform will create the UI Ingress with annotations for ALB and ACM. Requires the retail-store namespace and ui-svc to exist."
  type        = bool
  default     = false
}

# Optional overrides for reading sandbox remote state
variable "sandbox_state_bucket" {
  description = "S3 bucket name that stores the sandbox Terraform state"
  type        = string
  default     = null
}

variable "sandbox_state_key" {
  description = "S3 key for the sandbox Terraform state object"
  type        = string
  default     = null
}

variable "sandbox_state_region" {
  description = "Region of the sandbox state S3 bucket"
  type        = string
  default     = null
}

variable "sandbox_state_profile" {
  description = "Optional AWS profile to use when reading sandbox remote state (useful with SSO)"
  type        = string
  default     = null
}

variable "sandbox_state_role_arn" {
  description = "Optional IAM role ARN to assume when reading sandbox remote state"
  type        = string
  default     = null
}