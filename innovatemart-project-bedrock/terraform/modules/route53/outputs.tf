output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  value = aws_route53_zone.main.name
}

output "route53_records" {
  value = aws_route53_record.main.*.fqdn
}