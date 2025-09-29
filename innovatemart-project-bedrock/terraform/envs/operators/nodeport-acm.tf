# ACM Certificate for NodePort SSL (for CloudFront or external proxy)
resource "aws_acm_certificate" "nodeport_cert" {
  count             = var.ingress_hostname != null && !var.manage_ui_ingress ? 1 : 0
  domain_name       = var.ingress_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "innovatemart-nodeport-certificate"
    Environment = "sandbox"
  }
}

# Route53 validation records for NodePort certificate
resource "aws_route53_record" "nodeport_cert_validation" {
  for_each = var.route53_zone_id != null && var.ingress_hostname != null && !var.manage_ui_ingress ? {
    for dvo in aws_acm_certificate.nodeport_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate validation for NodePort
resource "aws_acm_certificate_validation" "nodeport_cert" {
  count           = var.route53_zone_id != null && var.ingress_hostname != null && !var.manage_ui_ingress ? 1 : 0
  certificate_arn = aws_acm_certificate.nodeport_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.nodeport_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}