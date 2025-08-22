terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "launch_template_id" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "tg_arn" { type = string }
variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}
variable "desired" {
  type = number
}

resource "aws_autoscaling_group" "asg_dr" {
  name                = "${var.project}-asg-dr"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired
  vpc_zone_identifier = var.app_subnet_ids

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  target_group_arns         = [var.tg_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project}-app-dr"
    propagate_at_launch = true
  }
  tag {
    key                 = "App"
    value               = "medical-api"
    propagate_at_launch = true
  }
}

output "asg_dr_name" { value = aws_autoscaling_group.asg_dr.name }
