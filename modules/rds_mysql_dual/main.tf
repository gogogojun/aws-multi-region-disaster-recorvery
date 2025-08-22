terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}



resource "aws_db_instance" "writer" {
  provider = aws.p

  identifier     = "${var.project}-mysql-writer"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class_writer

  username = var.db_username
  password = var.db_password
  db_name  = var.db_name

  allocated_storage   = 20
  storage_type        = "gp3"
  multi_az            = false
  publicly_accessible = false

  db_subnet_group_name       = aws_db_subnet_group.p.name
  vpc_security_group_ids     = var.db_sg_primary_ids
  backup_retention_period    = 1
  skip_final_snapshot        = true
  apply_immediately          = true
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = { Role = "writer" }
}

resource "aws_db_instance" "reader" {
  provider = aws.d

  identifier          = "${var.project}-mysql-reader"
  engine              = "mysql"
  engine_version      = "8.0"
  replicate_source_db = aws_db_instance.writer.arn
  instance_class      = var.db_instance_class_reader
  publicly_accessible = false

  db_subnet_group_name   = aws_db_subnet_group.d.name
  vpc_security_group_ids = var.db_sg_dr_ids

  apply_immediately          = true
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = { Role = "reader" }
}

resource "aws_db_subnet_group" "p" {
  provider   = aws.p
  name       = "${var.project}-db-subnet-p"
  subnet_ids = var.db_subnet_ids_primary
  tags       = { Name = "${var.project}-db-subnet-p" }
}

resource "aws_db_subnet_group" "d" {
  provider   = aws.d
  name       = "${var.project}-db-subnet-d"
  subnet_ids = var.db_subnet_ids_dr
  tags       = { Name = "${var.project}-db-subnet-d" }
}

output "writer_endpoint" { value = aws_db_instance.writer.address }
output "reader_endpoint" { value = aws_db_instance.reader.address }
output "d_subnetgroup" { value = aws_db_subnet_group.d.name }
output "p_subnetgroup" { value = aws_db_subnet_group.p.name }
