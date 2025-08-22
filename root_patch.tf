# Assumes providers aws.p (ap-northeast-2), aws.d (ap-northeast-3) already declared in your stack.
data "aws_caller_identity" "current" {}

locals {
  cf_distribution_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.distribution_id}"
}

# 1) MRAP over existing S3 buckets created by module.s3_static
module "s3_mrap" {
  source = "./modules/s3_mrap_attach"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project             = var.project
  primary_bucket_name = module.s3_static.primary_bucket
  dr_bucket_name      = module.s3_static.dr_bucket
  cf_distribution_id  = module.cdn.distribution_id
  depends_on          = [module.s3_static]
}

# 2) CloudFront: default=S3 MRAP, /api/* -> GA
module "cdn" {
  source = "./modules/cloudfront_mrap_api"

  project                = var.project
  mrap_alias             = module.s3_mrap.mrap_alias
  api_origin_domain_name = module.ga.dns_name
  # must be in us-east-1
  domain_names = [var.medical_domain]
}

# 3) Route53 records
module "dns" {
  source = "./modules/route53_records"

  hosted_zone_id            = var.hosted_zone_id
  medical_fqdn              = var.medical_domain # "medical.nextcloudlab.com"
  admin_fqdn                = var.admin_domain   # "admin.nextcloudlab.com"
  cloudfront_domain_name    = module.cdn.domain_name
  cloudfront_hosted_zone_id = module.cdn.hosted_zone_id
  ga_dns_name               = module.ga.dns_name
}

