terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}
variable "hosted_zone_id" { type = string }
variable "medical_fqdn" { type = string } # "medical.nextcloudlab.com"
variable "admin_fqdn" { type = string }   # "admin.nextcloudlab.com"
variable "cloudfront_domain_name" { type = string }
variable "cloudfront_hosted_zone_id" { type = string }
variable "ga_dns_name" { type = string }

resource "aws_route53_record" "medical" {
  zone_id = var.hosted_zone_id
  name    = var.medical_fqdn
  type    = "A"
  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "admin" {
  zone_id = var.hosted_zone_id
  name    = var.admin_fqdn
  type    = "CNAME"
  ttl     = 60
  records = [var.ga_dns_name]
}
output "medical_record" { value = aws_route53_record.medical.fqdn }
output "admin_record" { value = aws_route53_record.admin.fqdn }
