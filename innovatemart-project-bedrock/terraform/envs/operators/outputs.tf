# Operators Environment Outputs
# Purpose: Export ALB and SSL configuration details

# ALB Information
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.manage_ui_ingress ? kubernetes_ingress_v1.ui_ingress[0].status[0].load_balancer[0].ingress[0].hostname : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.manage_ui_ingress && var.route53_zone_id != null ? data.aws_lb.ui_alb[0].zone_id : null
}

# SSL Certificate Information
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.ingress_hostname != null ? aws_acm_certificate.ui_cert[0].arn : null
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = var.ingress_hostname != null ? aws_acm_certificate.ui_cert[0].status : null
}

# Domain Information
output "application_url" {
  description = "URL to access the application"
  value = var.manage_ui_ingress ? (
    var.ingress_hostname != null ? (
      var.route53_zone_id != null ? "https://${var.ingress_hostname}" : "https://${var.ingress_hostname} (DNS not configured)"
    ) : "http://${kubernetes_ingress_v1.ui_ingress[0].status[0].load_balancer[0].ingress[0].hostname}"
  ) : (
    var.duckdns_domain != null ? "http://${var.duckdns_domain}.duckdns.org:30080" : (
      var.ingress_hostname != null && var.route53_zone_id != null ? "http://${var.ingress_hostname}:30080" : "Use NodePort: kubectl get nodes -o wide, then http://[NODE-IP]:30080"
    )
  )
}

# DuckDNS Information
output "duckdns_info" {
  description = "DuckDNS configuration information"
  value = var.duckdns_domain != null ? {
    domain = "${var.duckdns_domain}.duckdns.org"
    http_url = "http://${var.duckdns_domain}.duckdns.org:30080"
    update_status = "Domain will be updated with node IP automatically"
  } : null
}

# NodePort Information
output "nodeport_access" {
  description = "NodePort access information"
  value = !var.manage_ui_ingress ? {
    http_port = "30080"
    https_port = "30443"
    access_command = "kubectl get nodes -o wide"
    url_format = "http://[NODE-IP]:30080"
  } : null
}

# Route53 Information
output "route53_record_name" {
  description = "Route53 record name"
  value       = var.route53_zone_id != null && var.ingress_hostname != null ? aws_route53_record.ui_domain[0].name : null
}

# Load Balancer Controller Status
output "aws_load_balancer_controller_status" {
  description = "Status of AWS Load Balancer Controller deployment"
  value       = helm_release.aws_load_balancer_controller.status
}