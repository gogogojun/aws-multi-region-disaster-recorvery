terraform {
  required_providers {
    aws = { source = "hashicorp/aws",
      configuration_aliases = [aws.us_east_1]
    }
  }
}


resource "aws_s3control_multi_region_access_point" "this" {
  provider = aws.us_east_1

  details {
    name = "${var.project}-mrap"
    public_access_block {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    region { bucket = var.primary_bucket_name }
    region { bucket = var.dr_bucket_name }
  }
}
output "mrap_alias" { value = aws_s3control_multi_region_access_point.this.alias }
output "mrap_arn" { value = aws_s3control_multi_region_access_point.this.arn }
