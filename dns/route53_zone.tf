terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "chris-nelson-terraform-state"
    key     = "dns/terraform.tfstate"
    region  = "us-east-1"
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

# Public hosted zone for the root domain
#
# The hosted zone is intended to be long lived so the assigned name servers
# remain stable. The prevent_destroy lifecycle rule ensures that the zone is
# not removed during a destroy operation on this stack.
resource "aws_route53_zone" "main" {
  name = var.root_domain

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Root hosted zone for ${var.root_domain}"
  }
}
