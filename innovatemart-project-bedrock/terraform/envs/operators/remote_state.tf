// Remote state to read outputs from the sandbox environment.
// Distinct from this stack's own backend (see backend.tf).

locals {
  // Base S3 config for the sandbox state location with sensible defaults
  sandbox_state_config_base = {
    bucket  = coalesce(var.sandbox_state_bucket, "innovatemart-terraform-state-eu-west-1-ma2025")
    key     = coalesce(var.sandbox_state_key, "sandbox/terraform.tfstate")
    region  = coalesce(var.sandbox_state_region, "eu-west-1")
    encrypt = true
  }

  // Add optional auth parameters only when provided to avoid nulls in config
  sandbox_state_config_auth = merge(
    var.sandbox_state_profile != null ? { profile = var.sandbox_state_profile } : {},
    var.sandbox_state_role_arn != null ? { role_arn = var.sandbox_state_role_arn } : {}
  )

  sandbox_state_config = merge(local.sandbox_state_config_base, local.sandbox_state_config_auth)
}

data "terraform_remote_state" "sandbox" {
  backend = "s3"
  config  = local.sandbox_state_config
}
