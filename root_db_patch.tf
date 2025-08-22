# expects provider aliases already defined in your FINAL stack:
# provider "aws" { alias = "p" region = "ap-northeast-2" }
# provider "aws" { alias = "d" region = "ap-northeast-3" }



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
