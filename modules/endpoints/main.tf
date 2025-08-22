terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "region" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "route_table_ids_for_s3" { type = list(string) }

resource "aws_security_group" "vpce" {
  name   = "vpce-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = var.route_table_ids_for_s3
  tags              = { Name = "vpce-s3" }
}

locals {
  services = ["ssm", "ec2messages", "ssmmessages", "logs"]
}

resource "aws_vpc_endpoint" "iface" {
  for_each            = toset(local.services)
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  private_dns_enabled = true
  subnet_ids          = var.app_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  tags                = { Name = "vpce-${each.value}" }
}

output "s3_gateway_id" { value = aws_vpc_endpoint.s3.id }
output "iface_ids" { value = { for k, v in aws_vpc_endpoint.iface : k => v.id } }
output "vpce_sg_id" { value = aws_security_group.vpce.id }
