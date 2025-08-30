output "primary_alb_dns" { value = module.alb_p.alb_dns }
output "dr_alb_dns" { value = module.alb_d.alb_dns }
output "primary_asg_name" { value = module.compute_p.asg_name }
output "primary_instance_profile_name" { value = module.iam_p.instance_profile_name }
output "ssm_document_name" { value = module.ssm_d.document_name }

output "dr_launch_template_id_for_drs" { value = module.compute_dr.launch_template_id }
output "dr_app_sg_id" { value = module.sec_d.app_sg_id }
output "dr_app_subnet_ids" { value = module.net_d.app_subnet_ids }
output "dr_tg_arn" { value = module.alb_d.tg_arn }

output "s3_primary_bucket" {
  value = module.s3_static.primary_bucket
}
output "s3_dr_bucket" {
  value = module.s3_static.dr_bucket
}



output "ga_accelerator_arn" { value = module.ga.accelerator_arn }
output "dr_asg_name" { value = module.compute_dr.asg_dr_name }
