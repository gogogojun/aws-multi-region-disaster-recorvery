terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# ===== Variables (기존 변수 유지 + db_port만 추가) =====
variable "vpc_id" { type = string }
variable "app_port" { type = number }                # 예: 8080
variable "alb_ingress_cidrs" { type = list(string) } # 예: ["0.0.0.0/0"]
variable "db_port" {                                 # ✅ 추가
  description = "DB port for MySQL"
  type        = number
  default     = 3306
}

# ===== ALB SG: 80/443 from Internet (CIDR 리스트) =====
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  # HTTPS
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===== App SG: only from ALB to app_port =====
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App security group (only from ALB)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===== DB SG: only from App to db_port (기본 3306) =====
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "DB security group (only from App)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB from App"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===== Outputs =====
output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id" { value = aws_security_group.db.id }
