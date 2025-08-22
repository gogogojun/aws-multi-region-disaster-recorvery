terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "project" { type = string }
variable "artifact_bucket" { type = string }
variable "artifact_prefix" { type = string }

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.artifact_bucket}",
      "arn:aws:s3:::${var.artifact_bucket}/${var.artifact_prefix}*"
    ]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "${var.project}-s3-read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2.name
}

output "instance_profile_name" { value = aws_iam_instance_profile.profile.name }
output "role_name" { value = aws_iam_role.ec2.name }

# ELBv2 Register/DeregisterTargets 권한 (해당 TG로 스코프 제한 권장: 예시는 와일드카드)
data "aws_iam_policy_document" "elb_register" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetHealth"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "elb_register" {
  name   = "${var.project}-elb-register"
  policy = data.aws_iam_policy_document.elb_register.json
}

resource "aws_iam_role_policy_attachment" "attach_elb_register" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.elb_register.arn
}
