terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "instance_type" { type = string }
variable "app_sg_id" { type = string }
variable "user_data_b64" { type = string }
variable "instance_profile_name" {type = string}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "lt_drs" {
  name_prefix            = "${var.project}-lt-drs-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  user_data              = var.user_data_b64
  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-app-d"
      App  = "medical-api"
    }
  }
}

output "launch_template_id" { value = aws_launch_template.lt_drs.id }
