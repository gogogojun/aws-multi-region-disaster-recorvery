terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

variable "project" { type = string }
variable "mrap_alias" { type = string }
variable "api_origin_domain_name" { type = string }
variable "acm_certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:077672914621:certificate/a5c1395d-3f08-4a4d-947f-11f70281a239"
}
variable "domain_names" {
  type    = list(string)
  default = []
}

locals {
  caching_disabled_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}



resource "aws_cloudfront_cache_policy" "optimized" {
  name        = "${var.project}-optimized"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = var.domain_names
  comment         = "${var.project} MRAP + /api via GA"
  tags       = { Project = "${var.project}-cdn"}
  origin {
    domain_name = "${var.mrap_alias}.accesspoint.s3-global.amazonaws.com"
    origin_id   = "s3-mrap"
    custom_origin_config {
      origin_protocol_policy = "https-only"
      https_port             = 443
      http_port              = 80
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    connection_attempts = 3
    connection_timeout  = 10
  }

  origin {
    domain_name = var.api_origin_domain_name
    origin_id   = "api-ga"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    connection_attempts = 3
    connection_timeout  = 10
  }

  default_cache_behavior {
    target_origin_id       = "s3-mrap"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.optimized.id
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-ga"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = local.caching_disabled_policy_id

    origin_request_policy_id = null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

}

output "domain_name" { value = aws_cloudfront_distribution.this.domain_name }
output "hosted_zone_id" { value = aws_cloudfront_distribution.this.hosted_zone_id }
output "distribution_id" { value = aws_cloudfront_distribution.this.id }
