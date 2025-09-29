variable "domain_name" {
  description = "The domain name for the Route 53 hosted zone."
  type        = string
}

variable "zone_id" {
  description = "The ID of the Route 53 hosted zone."
  type        = string
}

variable "record_name" {
  description = "The name of the DNS record to create."
  type        = string
}

variable "record_type" {
  description = "The type of the DNS record (e.g., A, CNAME)."
  type        = string
}

variable "record_ttl" {
  description = "The TTL (Time to Live) for the DNS record."
  type        = number
  default     = 300
}

variable "record_value" {
  description = "The value of the DNS record."
  type        = list(string)
}