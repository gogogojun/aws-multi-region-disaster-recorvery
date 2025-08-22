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
}

provider "aws" {
  alias  = "d"
  region = var.region_dr
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}