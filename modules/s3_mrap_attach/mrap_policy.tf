

variable "cf_distribution_id" {
  type = string
}

data "aws_caller_identity" "current" {}

data "aws_s3control_multi_region_access_point" "mrap" {
  provider   = aws.us_east_1
  account_id = data.aws_caller_identity.current.account_id
  name       = "${var.project}-mrap" # 예: "${var.project}-mrap"
}

resource "aws_s3control_multi_region_access_point_policy" "cf_only" {
  provider   = aws.us_east_1
  account_id = data.aws_caller_identity.current.account_id

  details {
    # MRAP 'name' (alias 아님) → 방금 만든 리소스의 name 사용
    name = "${var.project}-mrap"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid       = "AllowCloudFrontReadViaMRAP",
          Effect    = "Allow",
          Principal = { Service = "cloudfront.amazonaws.com" },
          Action    = ["s3:GetObject"], # ListBucket가 꼭 필요하지 않으면 제거 권장
          Resource = [
            # ✅ MRAP AccessPoint ARN (객체 전체): //* 중요
            "arn:aws:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${data.aws_s3control_multi_region_access_point.mrap.alias}/object/*"
          ],
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cf_distribution_id}"
            }
          }
        }
      ]
    })
  }
}