terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.p, aws.d]
    }
  }
}

locals {
  primary_bucket_name = "${var.bucket_name}-pr"
  dr_bucket_name      = "${var.bucket_name}-dr"
}

variable "project" { type = string }
variable "bucket_name" { type = string }

resource "aws_s3_bucket" "p" {
  provider      = aws.p
  bucket        = local.primary_bucket_name
  force_destroy = true
  tags          = { Project = var.project, Role = "static-primary" }
}
resource "aws_s3_bucket_versioning" "p" {
  provider = aws.p
  bucket   = aws_s3_bucket.p.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket" "d" {
  provider      = aws.d
  bucket        = local.dr_bucket_name
  force_destroy = true
  tags          = { Project = var.project, Role = "static-dr" }
}
resource "aws_s3_bucket_versioning" "d" {
  provider = aws.d
  bucket   = aws_s3_bucket.d.id
  versioning_configuration { status = "Enabled" }
}

data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication_role" {
  provider           = aws.p
  name               = "${var.project}-s3-repl-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

data "aws_iam_policy_document" "replication_policy" {
  statement {
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.p.arn]
  }
  statement {
    actions = [
      "s3:GetObjectVersion", "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication", "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.p.arn}/*"]
  }
  statement {
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"]
    resources = ["${aws_s3_bucket.d.arn}/*"]
  }
}

resource "aws_iam_policy" "replication_policy" {
  provider = aws.p
  name     = "${var.project}-s3-repl-policy"
  policy   = data.aws_iam_policy_document.replication_policy.json
}

resource "aws_iam_role_policy_attachment" "repl_attach" {
  provider   = aws.p
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_bucket_replication_configuration" "p_to_d" {
  provider = aws.p
  bucket   = aws_s3_bucket.p.id
  role     = aws_iam_role.replication_role.arn

  rule {
    id     = "p-to-d"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.d.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket_versioning.p, aws_s3_bucket_versioning.d]
}

output "primary_bucket" { value = aws_s3_bucket.p.bucket }
output "dr_bucket" { value = aws_s3_bucket.d.bucket }
output "primary_bucket_arn" { value = aws_s3_bucket.p.arn }
output "dr_bucket_arn" { value = aws_s3_bucket.d.arn }