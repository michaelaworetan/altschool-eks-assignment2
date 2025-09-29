output "acm_certificate_arn" {
  description = "ARN of the created ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "acm_certificate_id" {
  description = "ID of the created ACM certificate"
  value       = aws_acm_certificate.cert.id
}