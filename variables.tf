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
  default   = "asblk12345"
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

variable "enable_s3_static" { default = false }
variable "s3_primary_bucket_name" { default = "go-pr1" }
variable "s3_dr_bucket_name" { default = "go-dr1" }
