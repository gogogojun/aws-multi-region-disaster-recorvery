data "aws_availability_zones" "az_p" {
  provider = aws.p
  state    = "available"
}

data "aws_availability_zones" "az_d" {
  provider = aws.d
  state    = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs_p = slice(data.aws_availability_zones.az_p.names, 0, 2)
  azs_d = slice(data.aws_availability_zones.az_d.names, 0, 2)
  cf_distribution_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.distribution_id}"

}



# 1) Network (Primary & DR)
module "net_p" {
  source    = "./modules/network"
  providers = { aws = aws.p }

  project      = var.project
  vpc_cidr     = var.vpc_cidr_p
  public_cidrs = var.public_cidrs_p
  app_cidrs    = var.app_cidrs_p
  azs          = local.azs_p
}

module "net_d" {
  source    = "./modules/network"
  providers = { aws = aws.d }

  project      = var.project
  vpc_cidr     = var.vpc_cidr_d
  public_cidrs = var.public_cidrs_d
  app_cidrs    = var.app_cidrs_d
  azs          = local.azs_d
}

# 2) Security (SGs)
module "sec_p" {
  source    = "./modules/security"
  providers = { aws = aws.p }

  vpc_id            = module.net_p.vpc_id
  app_port          = var.app_port
  alb_ingress_cidrs = var.alb_ingress_cidrs
}

module "sec_d" {
  source    = "./modules/security"
  providers = { aws = aws.d }

  vpc_id            = module.net_d.vpc_id
  app_port          = var.app_port
  alb_ingress_cidrs = var.alb_ingress_cidrs
}

# 3) VPC Endpoints (Primary only - NATless SSM/S3/Logs)
module "ep_p" {
  source    = "./modules/endpoints"
  providers = { aws = aws.p }

  region                 = var.region_primary
  vpc_id                 = module.net_p.vpc_id
  vpc_cidr               = var.vpc_cidr_p
  app_subnet_ids         = module.net_p.app_subnet_ids
  route_table_ids_for_s3 = [module.net_p.app_route_table_id]
}

# 4) ALB (Primary & DR)
module "alb_p" {
  source    = "./modules/alb"
  providers = { aws = aws.p }

  name_suffix         = "p"
  vpc_id              = module.net_p.vpc_id
  public_subnet_ids   = module.net_p.public_subnet_ids
  alb_sg_id           = module.sec_p.alb_sg_id
  app_port            = var.app_port
  health_path         = var.health_path
  alb_certificate_arn = var.acm_arn_apne2
}

module "alb_d" {
  source    = "./modules/alb"
  providers = { aws = aws.d }

  name_suffix         = "d"
  vpc_id              = module.net_d.vpc_id
  public_subnet_ids   = module.net_d.public_subnet_ids
  alb_sg_id           = module.sec_d.alb_sg_id
  app_port            = var.app_port
  health_path         = var.health_path
  alb_certificate_arn = var.acm_arn_apne3
}

# 5) IAM for EC2 (SSM + S3 Read)
module "iam_p" {
  source    = "./modules/iam"
  providers = { aws = aws.p }

  project         = var.project
  artifact_bucket = var.artifact_bucket_p
  artifact_prefix = var.artifact_prefix
}

module "iam_d" {
  source    = "./modules/iam"
  providers = { aws = aws.d }

  project         = var.project
  artifact_bucket = var.artifact_bucket_d
  artifact_prefix = var.artifact_prefix
  count           = 0 #DR에서는 만들지 않음
}

# 6) Compute Primary (ASG/EC2)
module "compute_p" {
  source    = "./modules/compute_primary"
  providers = { aws = aws.p }

  project               = var.project
  instance_type         = var.instance_type
  desired               = var.desired
  min_size              = var.min_size
  max_size              = var.max_size
  app_subnet_ids        = module.net_p.app_subnet_ids
  app_sg_id             = module.sec_p.app_sg_id
  instance_profile_name = module.iam_p.instance_profile_name
  user_data_b64         = base64encode(var.user_data_bash)
  tg_arn                = module.alb_p.tg_arn
}

# 7) Compute DR (DRS용 Launch Template)
module "compute_dr" {
  source    = "./modules/compute_dr"
  providers = { aws = aws.d }

  project       = var.project
  instance_type = var.instance_type
  app_sg_id     = module.sec_d.app_sg_id
  user_data_b64 = base64encode(var.user_data_bash)
  instance_profile_name = module.iam_p.instance_profile_name
}

# 8) SSM Deploy Document
module "ssm_p" {
  source    = "./modules/ssm"
  providers = { aws = aws.p }

  project         = var.project
  artifact_bucket = var.artifact_bucket_p
  artifact_prefix = var.artifact_prefix
  systemd_service = var.systemd_service
}

module "ssm_d" {
  source    = "./modules/ssm"
  providers = { aws = aws.d }

  project         = var.project
  artifact_bucket = var.artifact_bucket_d
  artifact_prefix = var.artifact_prefix
  systemd_service = var.systemd_service
}


# 9) (Optional) S3 Static + CRR (Amplify 안쓰는 경우만)
module "s3_static" {
  source    = "./modules/s3_static"
  providers = { aws.p = aws.p, aws.d = aws.d }

  project     = var.project
  bucket_name = "${var.project}-web"
}

# 10) DB 구성(writer,read)
module "db" {
  source    = "./modules/rds_mysql_dual"
  providers = { aws.p = aws.p, aws.d = aws.d }

  project     = var.project
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  db_instance_class_writer = var.db_instance_class_writer
  db_instance_class_reader = var.db_instance_class_reader
  db_subnet_ids_primary    = module.net_p.app_subnet_ids
  db_subnet_ids_dr         = module.net_d.app_subnet_ids

  db_sg_primary_ids = [module.sec_p.db_sg_id]
  db_sg_dr_ids      = [module.sec_d.db_sg_id]
}

# 11) MRAP over existing S3 buckets created by module.s3_static
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

# 12) CloudFront: default=S3 MRAP, /api/* -> GA
module "cdn" {
  source = "./modules/cloudfront_mrap_api"

  project                = var.project
  mrap_alias             = module.s3_mrap.mrap_alias
  api_origin_domain_name = module.ga.dns_name
  # must be in us-east-1
  domain_names = [var.medical_domain]
}

# 13) Route53 records
module "dns" {
  source = "./modules/route53_records"

  hosted_zone_id            = var.hosted_zone_id
  medical_fqdn              = var.medical_domain # "medical.nextcloudlab.com"
  admin_fqdn                = var.admin_domain   # "admin.nextcloudlab.com"
  cloudfront_domain_name    = module.cdn.domain_name
  cloudfront_hosted_zone_id = module.cdn.hosted_zone_id
  ga_dns_name               = module.ga.dns_name
}
# === Global Accelerator ===
module "ga" {
  source = "./modules/ga"

  project         = var.project
  health_path     = var.health_path
  primary_region  = var.region_primary
  dr_region       = var.region_dr
  alb_arn_primary = module.alb_p.alb_arn
  alb_arn_dr      = module.alb_d.alb_arn
}

# === DR ASG (pre-provision, desired=0) ===
module "compute_dr_asg" {
  source    = "./modules/compute_dr_asg"
  providers = { aws = aws.d }

  project            = var.project
  launch_template_id = module.compute_dr.launch_template_id
  app_subnet_ids     = module.net_d.app_subnet_ids
  tg_arn             = module.alb_d.tg_arn

  min_size = 2
  max_size = 4
  desired  = 2
}
