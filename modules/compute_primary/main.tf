terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "instance_type" { type = string }
variable "desired" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "app_subnet_ids" { type = list(string) }
variable "app_sg_id" { type = string }
variable "instance_profile_name" { type = string }
variable "user_data_b64" { type = string }
variable "tg_arn" { type = string }

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.project}-lt-p-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = var.user_data_b64

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.app_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-app-p"
      App  = "medical-api"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.project}-asg-p"
  desired_capacity    = var.desired
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.app_subnet_ids

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns         = [var.tg_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project}-app-p"
    propagate_at_launch = true
  }
  tag {
    key                 = "App"
    value               = "medical-api"
    propagate_at_launch = true
  }
}

output "asg_name" { value = aws_autoscaling_group.asg.name }
output "launch_template_id" { value = aws_launch_template.lt.id }
