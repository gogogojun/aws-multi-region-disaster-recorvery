terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }
}

provider "aws" {
  alias  = "p"
  region = var.region_primary
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "d"
  region = var.region_dr
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
  default_tags {
    tags = local.common_tags
  }
}