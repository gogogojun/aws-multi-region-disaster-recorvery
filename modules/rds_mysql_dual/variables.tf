variable "project" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class_writer" { type = string }
variable "db_instance_class_reader" { type = string }
variable "db_subnet_ids_primary" {
  type = list(string)
}
variable "db_subnet_ids_dr" {
  type = list(string)
}
variable "db_sg_primary_ids" { type = list(string) }
variable "db_sg_dr_ids" { type = list(string) }