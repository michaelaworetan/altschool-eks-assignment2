resource "aws_route53_zone" "main" {
  name = var.domain_name
  comment = "Hosted zone for ${var.domain_name}"
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}