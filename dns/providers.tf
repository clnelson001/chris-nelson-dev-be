terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "chris-nelson-dev-tfstate"
    key     = "dns/terraform.tfstate"
    region  = "us-west-1"
    profile = "personal"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "personal"
}
