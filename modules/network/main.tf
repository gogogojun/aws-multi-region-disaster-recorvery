terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "vpc_cidr" { type = string }
variable "public_cidrs" { type = list(string) }
variable "app_cidrs" { type = list(string) }
variable "azs" { type = list(string) }

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_subnet" "public" {
  for_each                = { for i, az in var.azs : i => { az = az, cidr = var.public_cidrs[i] } }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-pub-${each.value.az}" }
}

resource "aws_subnet" "app" {
  for_each          = { for i, az in var.azs : i => { az = az, cidr = var.app_cidrs[i] } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.project}-app-${each.value.az}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project}-rt-public" }
}

resource "aws_route_table_association" "pub_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-rt-app" }
}

resource "aws_route_table_association" "app_assoc" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}

output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = var.vpc_cidr }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "app_subnet_ids" { value = [for s in aws_subnet.app : s.id] }
output "public_route_table_id" { value = aws_route_table.public.id }
output "app_route_table_id" { value = aws_route_table.app.id }
