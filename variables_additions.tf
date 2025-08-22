variable "acm_cert_arn_us_east_1" {
  type    = string
  default = "arn:aws:acm:ap-northeast-2:077672914621:certificate/59c563eb-95dd-41ff-bd65-ec52b9271c22"
}



variable "hosted_zone_id" {
  type    = string
  default = "Z075370721NCBSLEWW4JM"
}
variable "medical_domain" {
  type    = string
  default = "medical.nextcloudlab.com"
}
variable "admin_domain" {
  type    = string
  default = "admin.nextcloudlab.com"
}
