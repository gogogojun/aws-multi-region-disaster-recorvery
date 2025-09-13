terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "health_path" { type = string }
variable "primary_region" { type = string }
variable "dr_region" { type = string }
variable "alb_arn_primary" { type = string }
variable "alb_arn_dr" { type = string }

resource "aws_globalaccelerator_accelerator" "this" {
  name    = "${var.project}-ga"
  enabled = true
  tags       = { Name = "${var.project}-ga" }
}


resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.http.id
  endpoint_group_region = var.primary_region

  health_check_protocol = "HTTPS"
  health_check_port     = 443
  health_check_path     = var.health_path

  # 기본: 모든 트래픽 100%
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = var.alb_arn_primary
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "dr" {
  listener_arn          = aws_globalaccelerator_listener.http.id
  endpoint_group_region = var.dr_region

  health_check_protocol = "HTTPS"
  health_check_port     = 443
  health_check_path     = var.health_path

  # 기본: 대기(0%), 장애 시 헬스체크로 자동 전환
  traffic_dial_percentage = 0

  endpoint_configuration {
    endpoint_id = var.alb_arn_dr
    weight      = 100
  }
}

output "accelerator_arn" { value = aws_globalaccelerator_accelerator.this.id }
output "dns_name" {
  value = aws_globalaccelerator_accelerator.this.dns_name
}