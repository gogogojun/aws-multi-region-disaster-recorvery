variable "project" { default = "medical-dr" }
variable "region_primary" { default = "ap-northeast-2" }
variable "region_dr" { default = "ap-northeast-3" }

variable "vpc_cidr_p" { default = "10.10.0.0/16" }
variable "vpc_cidr_d" { default = "10.20.0.0/16" }

variable "public_cidrs_p" { default = ["10.10.10.0/24", "10.10.20.0/24"] }
variable "app_cidrs_p" { default = ["10.10.110.0/24", "10.10.120.0/24"] }
variable "public_cidrs_d" { default = ["10.20.10.0/24", "10.20.20.0/24"] }
variable "app_cidrs_d" { default = ["10.20.110.0/24", "10.20.120.0/24"] }

variable "app_port" { default = 8080 }
variable "health_path" { default = "/healthz" }

variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "instance_type" { default = "t3.micro" }
variable "desired" { default = 2 }
variable "min_size" { default = 2 }
variable "max_size" { default = 4 }

variable "artifact_bucket_p" { default = "go-artifacts-seoul" }
variable "artifact_prefix" { default = "app/" }
variable "systemd_service" { default = "app" }

variable "artifact_bucket_d" { default = "go-artifacts-seoul" }

variable "user_data_bash" {
  default = <<-EOF
  #!/bin/bash
  echo "booting $(date)" >> /var/log/userdata.log
  EOF
}

variable "db_name" {
  type    = string
  default = "drdb"
}
variable "db_username" {
  type    = string
  default = "admin"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class_writer" {
  type    = string
  default = "db.t3.small"
}
variable "db_instance_class_reader" {
  type    = string
  default = "db.t3.small"
}


variable "acm_arn_apne2" {
  type    = string
  default = null
} # 서울(2) 인증서 ARN
variable "acm_arn_apne3" {
  type    = string
  default = null
} # 오사카(3) 인증서 ARN

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