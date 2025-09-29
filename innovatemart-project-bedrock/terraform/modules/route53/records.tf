resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name     = "www.${var.domain_name}"
  type     = "A"
  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  zone_id = var.zone_id
  name     = "api.${var.domain_name}"
  type     = "A"
  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}