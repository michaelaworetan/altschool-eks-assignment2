variable "domain_name" {
  description = "The primary domain name for the ACM certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "Optional additional domain names (SANs) for the certificate."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Hosted zone ID in Route53 where DNS validation records will be created."
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to the ACM certificate."
  type        = map(string)
  default     = {}
}