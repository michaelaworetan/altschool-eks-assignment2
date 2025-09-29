# ACM Certificate for SSL/TLS
resource "aws_acm_certificate" "ui_cert" {
  count             = var.ingress_hostname != null ? 1 : 0
  domain_name       = var.ingress_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "innovatemart-ui-certificate"
    Environment = "sandbox"
  }
}

# Route53 validation records (if zone provided)
resource "aws_route53_record" "cert_validation" {
  for_each = var.route53_zone_id != null && var.ingress_hostname != null ? {
    for dvo in aws_acm_certificate.ui_cert[0].domain_validation_options : dvo.domain_name => {
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

# Certificate validation
resource "aws_acm_certificate_validation" "ui_cert" {
  count           = var.route53_zone_id != null && var.ingress_hostname != null ? 1 : 0
  certificate_arn = aws_acm_certificate.ui_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}