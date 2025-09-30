# Operators Environment Outputs
# Purpose: Export ALB and SSL configuration details

# ALB Information
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.manage_ui_ingress ? try(kubernetes_ingress_v1.ui[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = null
}

# SSL Certificate Information
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = try(module.acm[0].acm_certificate_arn, null)
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = try(module.acm[0].acm_certificate_status, null)
}

# Domain Information
output "application_url" {
  description = "URL to access the application"
  value = var.manage_ui_ingress ? (
    var.ingress_hostname != null ? (
      try(module.acm[0].acm_certificate_arn, null) != null ? "https://${var.ingress_hostname}" : "http://${var.ingress_hostname}"
    ) : try("http://${kubernetes_ingress_v1.ui[0].status[0].load_balancer[0].ingress[0].hostname}", "ALB DNS not available")
  ) : "ALB Ingress not enabled"
}

# Route53 Information
output "route53_record_name" {
  description = "Route53 record name"
  value       = var.route53_zone_id != null && var.ingress_hostname != null ? var.ingress_hostname : null
}

# Load Balancer Controller Status
output "aws_load_balancer_controller_status" {
  description = "Status of AWS Load Balancer Controller deployment"
  value       = helm_release.aws_load_balancer_controller.status
}